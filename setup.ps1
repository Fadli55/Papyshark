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
    Write-Host "`n[INFO] Java tidak terdeteksi. Mengunduh OpenJDK 21 Portable (~190 MB)..." -ForegroundColor Cyan
    Write-Host "Dilengkapi fitur Auto-Retry tahan koneksi lemot..."
    
    $jdkZip = "$SPARK_BASE\jdk21.zip"
    $jdkUrl = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49e699280e63b7718c42/13/GPL/openjdk-21.0.2_windows-x64_bin.zip"
    
    $downloadSuccess = $false
    for ($i = 1; $i -le 5; $i++) {
        try {
            Write-Host "Mencoba download Java (Percobaan ke-$i)..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0")
            $wc.DownloadFile($jdkUrl, $jdkZip)
            $downloadSuccess = $true
            break
        } catch {
            Write-Host "Koneksi terputus: $($_.Exception.Message). Mengulang dalam 3 detik..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }

    if (-not $downloadSuccess) {
        Write-Host "[ERROR] Gagal mendownload Java JDK. Silakan cek koneksi internet dan jalankan ulang." -ForegroundColor Red
        Read-Host "Tekan Enter untuk keluar"
        exit 1
    }

    Write-Host "[INFO] Mengekstrak Java JDK 21..." -ForegroundColor Cyan
    Expand-Archive -Path $jdkZip -DestinationPath $SPARK_BASE -Force
    
    if (Test-Path "$SPARK_BASE\jdk-21.0.2") {
        Rename-Item -Path "$SPARK_BASE\jdk-21.0.2" -NewName "jdk-21" -Force
    }
    if (Test-Path $jdkZip) {
        Remove-Item -Path $jdkZip -Force
    }
    Write-Host "[OK] Java JDK 21 siap di folder jdk-21!" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 2. CEK / INSTALL PYTHON 3.12
# ------------------------------------------------------------------
Write-Host "`n[2/4] Memeriksa Python..." -ForegroundColor Yellow
$pythonExe = $null

if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonExe = (Get-Command python).Source
} elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe") {
    $pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
} elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe") {
    $pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe"
}

if ($pythonExe) {
    Write-Host "[OK] Python terdeteksi: $pythonExe" -ForegroundColor Green
    & $pythonExe --version
} else {
    Write-Host "[INFO] Python tidak terdeteksi. Mengunduh installer resmi Python 3.12..." -ForegroundColor Cyan
    $pyInstaller = "$SPARK_BASE\python-installer.exe"
    $pyUrl = "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
    
    $pySuccess = $false
    for ($i = 1; $i -le 5; $i++) {
        try {
            Write-Host "Mencoba download Python (Percobaan ke-$i)..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($pyUrl, $pyInstaller)
            $pySuccess = $true
            break
        } catch {
            Write-Host "Koneksi terputus: $($_.Exception.Message). Mengulang dalam 3 detik..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }

    if (-not $pySuccess) {
        Write-Host "[ERROR] Gagal mendownload Python." -ForegroundColor Red
        Read-Host "Tekan Enter untuk keluar"
        exit 1
    }

    Write-Host "[INFO] Menginstall Python 3.12 secara otomatis..." -ForegroundColor Cyan
    Start-Process -FilePath $pyInstaller -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_test=0" -Wait
    Remove-Item -Path $pyInstaller -Force
    
    $pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    Write-Host "[OK] Python berhasil dipasang!" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 3. MEMBUAT VIRTUAL ENVIRONMENT PYTHON
# ------------------------------------------------------------------
Write-Host "`n[3/4] Menyiapkan Virtual Environment Python (env)..." -ForegroundColor Yellow
$venvDir = "$SPARK_BASE\env"
if (-not (Test-Path $venvDir)) {
    Write-Host "[INFO] Membuat virtual environment di $venvDir..." -ForegroundColor Cyan
    & $pythonExe -m venv $venvDir
} else {
    Write-Host "[OK] Environment 'env' sudah tersedia." -ForegroundColor Green
}

# ------------------------------------------------------------------
# 4. INSTALL DEPENDENCIES (PYSPARK, JUPYTER, PANDAS)
# ------------------------------------------------------------------
Write-Host "`n[4/4] Menginstall PySpark, Jupyter, dan dependensi (Anti-Timeout)..." -ForegroundColor Yellow
$pipExe = "$venvDir\Scripts\pip.exe"
$pyVenvExe = "$venvDir\Scripts\python.exe"

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
