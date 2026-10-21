# Setup Otomatis Spark Cluster (Python, Java, PySpark, Jupyter)
$ErrorActionPreference = "Continue"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  SETUP OTOMATIS SPARK CLUSTER (FULL ZERO-CONFIG)      " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Script ini menyiapkan Java, Python, PySpark, dan Jupyter"
Write-Host "secara otomatis tanpa install manual."
Write-Host "========================================================`n"

$SPARK_BASE = Split-Path -Parent $MyInvocation.MyCommand.Path

# ------------------------------------------------------------------
# 1. CEK / DOWNLOAD JAVA JDK 21 PORTABLE
# ------------------------------------------------------------------
Write-Host "[1/4] Memeriksa Java JDK..." -ForegroundColor Yellow
$javaFound = $false

if (Test-Path "$SPARK_BASE\jdk-21\bin\java.exe") {
    Write-Host "[OK] Ditemukan Java JDK lokal di folder repo!" -ForegroundColor Green
    $javaFound = $true
} elseif (Get-Command java -ErrorAction SilentlyContinue) {
    $javaPath = (Get-Command java).Source
    Write-Host "[OK] Java terdeteksi di sistem: $javaPath" -ForegroundColor Green
    $javaFound = $true
} elseif (Test-Path "C:\Program Files\Java\jdk-21*") {
    Write-Host "[OK] Ditemukan JDK 21 di C:\Program Files\Java!" -ForegroundColor Green
    $javaFound = $true
} elseif (Test-Path "C:\Program Files\Java\jdk-17*") {
    Write-Host "[OK] Ditemukan JDK 17 di C:\Program Files\Java!" -ForegroundColor Green
    $javaFound = $true
}

if (-not $javaFound) {
    Write-Host "`n[INFO] Java tidak terdeteksi. Mengunduh Adoptium Eclipse Temurin JDK 21 (~195 MB)..." -ForegroundColor Cyan
    Write-Host "Menggunakan cURL dengan resume & retry agar stabil..."
    
    $jdkZip = "$SPARK_BASE\jdk21.zip"
    $jdkUrl = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_windows_hotspot_21.0.5_11.zip"
    
    $curlExe = (Get-Command curl.exe -ErrorAction SilentlyContinue)
    $downloadSuccess = $false
    
    if ($curlExe) {
        Write-Host "Mengunduh via curl.exe..."
        & curl.exe -L -C - --retry 5 --retry-delay 3 --connect-timeout 30 -o "$jdkZip" "$jdkUrl"
        if ($LASTEXITCODE -eq 0 -and (Test-Path $jdkZip)) {
            $downloadSuccess = $true
        }
    }
    
    if (-not $downloadSuccess) {
        Write-Host "Mengunduh via WebClient..."
        for ($i = 1; $i -le 5; $i++) {
            try {
                Write-Host "Percobaan ke-$i..."
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                $wc.DownloadFile($jdkUrl, $jdkZip)
                $downloadSuccess = $true
                break
            } catch {
                Write-Host "Gagal: $($_.Exception.Message). Mengulang dalam 3 detik..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        }
    }

    if (-not $downloadSuccess -or -not (Test-Path $jdkZip)) {
        Write-Host "[ERROR] Gagal mendownload Java JDK dari server GitHub." -ForegroundColor Red
        Write-Host "Silakan download manual JDK 21 dari: https://adoptium.net/temurin/releases/?version=21" -ForegroundColor Yellow
        Read-Host "Tekan Enter untuk keluar"
        exit 1
    }

    Write-Host "[INFO] Mengekstrak Java JDK 21 (Harap tunggu)..." -ForegroundColor Cyan
    Expand-Archive -Path $jdkZip -DestinationPath $SPARK_BASE -Force
    
    $extractedFolder = Get-ChildItem -Path $SPARK_BASE -Directory -Filter "jdk-21*" | Where-Object { $_.Name -ne "jdk-21" } | Select-Object -First 1
    if ($extractedFolder) {
        Rename-Item -Path $extractedFolder.FullName -NewName "jdk-21" -Force
    }
    
    if (Test-Path $jdkZip) {
        Remove-Item -Path $jdkZip -Force
    }
    Write-Host "[OK] Java JDK 21 siap di folder jdk-21!" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 2. CEK / INSTALL PYTHON (ABSOLUT VALIDATION)
# ------------------------------------------------------------------
Write-Host "`n[2/4] Memeriksa Python..." -ForegroundColor Yellow

function Test-PythonExe($path) {
    if (-not (Test-Path $path)) { return $false }
    try {
        $out = & $path -c "import sys; print(sys.version_info.major)" 2>$null
        if ($out -eq "3") { return $true }
    } catch {
        return $false
    }
    return $false
}

$pythonExe = $null

# 1. Cek dari command python jika bukan alias WindowsApps
$systemPy = (Get-Command python -ErrorAction SilentlyContinue)
if ($systemPy -and ($systemPy.Source -notmatch "WindowsApps")) {
    if (Test-PythonExe $systemPy.Source) {
        $pythonExe = $systemPy.Source
    }
}

# 2. Cek direktori umum instalasi Python di Windows
if (-not $pythonExe) {
    $commonPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "$env:ProgramFiles\Python311\python.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-PythonExe $p) {
            $pythonExe = $p
            break
        }
    }
}

if ($pythonExe) {
    Write-Host "[OK] Python valid terdeteksi: $pythonExe" -ForegroundColor Green
    & $pythonExe --version
} else {
    Write-Host "[INFO] Python asli tidak terdeteksi. Mengunduh installer resmi Python 3.12..." -ForegroundColor Cyan
    $pyInstaller = "$SPARK_BASE\python-installer.exe"
    $pyUrl = "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
    
    $pySuccess = $false
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        Write-Host "Mengunduh Python via curl..."
        & curl.exe -L -C - --retry 5 --retry-delay 3 -o "$pyInstaller" "$pyUrl"
        if ($LASTEXITCODE -eq 0 -and (Test-Path $pyInstaller)) {
            $pySuccess = $true
        }
    }
    
    if (-not $pySuccess) {
        for ($i = 1; $i -le 5; $i++) {
            try {
                Write-Host "Percobaan ke-$i..."
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($pyUrl, $pyInstaller)
                $pySuccess = $true
                break
            } catch {
                Write-Host "Gagal: $($_.Exception.Message). Mengulang dalam 3 detik..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        }
    }

    if (-not $pySuccess) {
        Write-Host "[ERROR] Gagal mendownload Python." -ForegroundColor Red
        Read-Host "Tekan Enter untuk keluar"
        exit 1
    }

    Write-Host "[INFO] Menginstall Python 3.12 secara otomatis (Harap tunggu)..." -ForegroundColor Cyan
    Start-Process -FilePath $pyInstaller -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_test=0" -Wait
    Remove-Item -Path $pyInstaller -Force
    
    $pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    if (-not (Test-PythonExe $pythonExe)) {
        Write-Host "[ERROR] Python selesai diinstall tetapi file python.exe tidak ditemukan di $pythonExe" -ForegroundColor Red
        Write-Host "Silakan download dan install Python manual dari: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "Jangan lupa centang 'Add python.exe to PATH'!" -ForegroundColor Yellow
        Read-Host "Tekan Enter untuk keluar"
        exit 1
    }
    Write-Host "[OK] Python 3.12 berhasil dipasang!" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 3. MEMBUAT VIRTUAL ENVIRONMENT PYTHON
# ------------------------------------------------------------------
Write-Host "`n[3/4] Menyiapkan Virtual Environment Python (env)..." -ForegroundColor Yellow
$venvDir = "$SPARK_BASE\env"
$pyVenvExe = "$venvDir\Scripts\python.exe"

# Hapus folder env jika korup/kosong tanpa python.exe
if ((Test-Path $venvDir) -and (-not (Test-Path $pyVenvExe))) {
    Write-Host "[INFO] Menemukan folder env rusak / tidak lengkap. Membersihkan..." -ForegroundColor Cyan
    Remove-Item -Path $venvDir -Recurse -Force
}

if (-not (Test-Path $venvDir)) {
    Write-Host "[INFO] Membuat virtual environment di $venvDir..." -ForegroundColor Cyan
    & $pythonExe -m venv $venvDir
}

if (-not (Test-Path $pyVenvExe)) {
    Write-Host "[ERROR] Gagal membuat virtual environment di $venvDir!" -ForegroundColor Red
    Write-Host "Pastikan antivirus tidak memblokir pembuatan file script." -ForegroundColor Yellow
    Read-Host "Tekan Enter untuk keluar"
    exit 1
}

Write-Host "[OK] Environment 'env' siap digunakan!" -ForegroundColor Green

# ------------------------------------------------------------------
# 4. INSTALL DEPENDENCIES (PYSPARK, JUPYTER, PANDAS)
# ------------------------------------------------------------------
Write-Host "`n[4/4] Menginstall PySpark, Jupyter, dan dependensi (Anti-Timeout)..." -ForegroundColor Yellow
$pipExe = "$venvDir\Scripts\pip.exe"

& $pyVenvExe -m pip install --upgrade pip --default-timeout=1000 --retries 10
& $pipExe install -r "$SPARK_BASE\requirements.txt" --default-timeout=1000 --retries 10

if (-not (Test-Path "$SPARK_BASE\notebooks")) {
    New-Item -ItemType Directory -Path "$SPARK_BASE\notebooks" -Force | Out-Null
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "  [BERHASIL] SEMUA SETUP SELESAI & SIAP DIGUNAKAN!      " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Langkah praktikum selanjutnya:"
Write-Host "1. Buka config\env.cmd dengan Notepad."
Write-Host "2. Masukkan IP Radmin Master di: set MASTER_IP=..."
Write-Host "3. Masukkan IP Radmin PC-mu di  : set LOCAL_HOST_IP=..."
Write-Host "4. Jalankan:"
Write-Host "   - PC Worker : Klik 2x start-worker.cmd"
Write-Host "   - PC Master : Klik 2x start-master.cmd"
Write-Host "   - Jupyter   : Klik 2x start-jupyter.cmd (copy link ke browser)"
Write-Host "========================================================`n"
Read-Host "Tekan Enter untuk menutup"
