@echo off
setlocal enabledelayedexpansion
title Setup Otomatis Spark Environment (Full Auto)
echo ========================================================
echo   SETUP OTOMATIS SPARK CLUSTER (FULL ZERO-CONFIG)
echo ========================================================
echo Script ini akan menyiapkan semua kebutuhan (Java, Python,
echo PySpark, Jupyter) secara otomatis tanpa perlu install manual!
echo ========================================================
echo.

set "SPARK_BASE=%~dp0"
if "%SPARK_BASE:~-1%"=="\" set "SPARK_BASE=%SPARK_BASE:~0,-1%"

:: ---------------------------------------------------------
:: FUNGSI DOWNLOADER POWERSHELL ANTI-TIMEOUT DENGAN RETRY
:: ---------------------------------------------------------

:: ---------------------------------------------------------
:: 1. CEK / DOWNLOAD PORTABLE JAVA JDK 21
:: ---------------------------------------------------------
echo [1/4] Memeriksa Java JDK...
set "JAVA_FOUND=0"

if exist "%SPARK_BASE%\jdk-21\bin\java.exe" (
    echo [OK] Ditemukan Java JDK lokal di folder repo!
    set "JAVA_FOUND=1"
    goto :JAVA_CHECK_DONE
)

where java >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('where java') do (
        echo [OK] Java terdeteksi di sistem: %%i
        set "JAVA_FOUND=1"
        goto :JAVA_CHECK_DONE
    )
)

if exist "C:\Program Files\Java\jdk-21*" (
    echo [OK] Ditemukan JDK 21 di C:\Program Files\Java!
    set "JAVA_FOUND=1"
    goto :JAVA_CHECK_DONE
)
if exist "C:\Program Files\Java\jdk-17*" (
    echo [OK] Ditemukan JDK 17 di C:\Program Files\Java!
    set "JAVA_FOUND=1"
    goto :JAVA_CHECK_DONE
)

:JAVA_CHECK_DONE
if "%JAVA_FOUND%"=="0" (
    echo.
    echo [INFO] Java tidak terdeteksi. Mengunduh OpenJDK 21 Portable (~190 MB)...
    echo Menggunakan mode Anti-Timeout (Auto-Retry)...
    
    powershell -Command "$wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); $success = $false; for ($i=1; $i -le 5; $i++) { try { Write-Host \"Percobaan download Java ke-$i...\"; $wc.DownloadFile('https://download.java.net/java/GA/jdk21.0.2/f2283984656d49e699280e63b7718c42/13/GPL/openjdk-21.0.2_windows-x64_bin.zip', '%SPARK_BASE%\jdk21.zip'); $success = $true; break } catch { Write-Host \"Download terputus, mengulang... ($($_.Exception.Message))\"; Start-Sleep -Seconds 3 } }; if (-not $success) { exit 1 }"
    
    if errorlevel 1 (
        echo [ERROR] Gagal mendownload Java JDK karena koneksi bermasalah. Jalankan ulang script setup.cmd ini.
        pause
        exit /b 1
    )

    echo [INFO] Mengekstrak Java JDK 21...
    powershell -Command "Expand-Archive -Path '%SPARK_BASE%\jdk21.zip' -DestinationPath '%SPARK_BASE%' -Force"
    
    if exist "%SPARK_BASE%\jdk-21.0.2" (
        rename "%SPARK_BASE%\jdk-21.0.2" jdk-21
    )
    if exist "%SPARK_BASE%\jdk21.zip" (
        del /f /q "%SPARK_BASE%\jdk21.zip"
    )
    echo [OK] Java JDK 21 siap digunakan di %SPARK_BASE%\jdk-21!
)

:: ---------------------------------------------------------
:: 2. CEK / DOWNLOAD PORTABLE PYTHON 3.12 (JIKA BELUM ADA PYTHON)
:: ---------------------------------------------------------
echo.
echo [2/4] Memeriksa Python...
set "PYTHON_EXE="

:: Cek apakah user punya python lokal di sistem
where python >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('where python') do (
        set "PYTHON_EXE=%%i"
        goto :PYTHON_CHECK_DONE
    )
)

:: Cek apakah ada python lokal di AppData
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    goto :PYTHON_CHECK_DONE
)
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :PYTHON_CHECK_DONE
)

:PYTHON_CHECK_DONE
if not "%PYTHON_EXE%"=="" (
    echo [OK] Python terdeteksi di sistem: !PYTHON_EXE!
    "!PYTHON_EXE!" --version
) else (
    echo [INFO] Python tidak terdeteksi di PC kamu.
    echo Mengunduh installer Python resmi Windows...
    powershell -Command "$wc = New-Object System.Net.WebClient; $success = $false; for ($i=1; $i -le 5; $i++) { try { Write-Host \"Percobaan download Python ke-$i...\"; $wc.DownloadFile('https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe', '%SPARK_BASE%\python-installer.exe'); $success = $true; break } catch { Write-Host \"Koneksi lemot, mengulang... ($($_.Exception.Message))\"; Start-Sleep -Seconds 3 } }; if (-not $success) { exit 1 }"
    
    echo [INFO] Menginstall Python 3.12 secara otomatis...
    "%SPARK_BASE%\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_test=0
    
    del /f /q "%SPARK_BASE%\python-installer.exe"
    set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    echo [OK] Python berhasil dipasang!
)

:: ---------------------------------------------------------
:: 3. BUAT VIRTUAL ENVIRONMENT PYTHON
:: ---------------------------------------------------------
echo.
echo [3/4] Menyiapkan Virtual Environment Python (env)...
if not exist "%SPARK_BASE%\env" (
    echo [INFO] Membuat environment di %SPARK_BASE%\env...
    "!PYTHON_EXE!" -m venv "%SPARK_BASE%\env"
) else (
    echo [OK] Environment 'env' sudah tersedia.
)

:: ---------------------------------------------------------
:: 4. INSTALL DEPENDENCIES DENGAN TIMEOUT LAMA & AUTO-RETRY
:: ---------------------------------------------------------
echo.
echo [4/4] Menginstall PySpark, Jupyter, dan modul pendukung...
echo Menggunakan opsi --default-timeout=1000 dan auto-retry agar tahan WiFi lemot!

"%SPARK_BASE%\env\Scripts\python.exe" -m pip install --upgrade pip --default-timeout=1000 --retries 10

"%SPARK_BASE%\env\Scripts\pip.exe" install -r "%SPARK_BASE%\requirements.txt" --default-timeout=1000 --retries 10

if not exist "%SPARK_BASE%\notebooks" (
    mkdir "%SPARK_BASE%\notebooks"
)

echo.
echo ========================================================
echo   [BERHASIL] SEMUA SETUP SELESAI ^& SIAP DIGUNAKAN!
echo ========================================================
echo Temanmu TIDAK PERLU install apa-apa lagi!
echo.
echo Langkah selanjutnya sebelum mulai:
echo 1. Hubungkan Radmin VPN ke Room Kelompok.
echo 2. Buka config\env.cmd dengan Notepad:
echo    - Masukkan IP Radmin Master di: set MASTER_IP=...
echo    - Masukkan IP Radmin PC-mu di  : set LOCAL_HOST_IP=...
echo 3. Jalankan:
echo    - PC Worker : Klik 2x start-worker.cmd
echo    - PC Master : Klik 2x start-master.cmd
echo    - Jupyter   : Klik 2x start-jupyter.cmd (copy link ke browser)
echo ========================================================
pause
