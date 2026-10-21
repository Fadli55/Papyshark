@echo off
title Setup Otomatis Spark Environment
echo ========================================================
echo   SETUP OTOMATIS SPARK & JUPYTER DI PC KAMU
echo ========================================================
echo.

:: 1. Cek Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python tidak terdeteksi di PATH!
    echo Silakan install Python 3.10, 3.11, atau 3.12 dan centang "Add python.exe to PATH".
    pause
    exit /b
)

:: 2. Buat folder env jika belum ada
if not exist "%~dp0env" (
    echo [1/3] Membuat virtual environment di folder 'env'...
    python -m venv "%~dp0env"
) else (
    echo [1/3] Folder virtual environment 'env' sudah ada.
)

:: 3. Install dependencies dari requirements.txt
echo [2/3] Menginstall PySpark, Jupyter, dan modul pendukung...
"%~dp0env\Scripts\python.exe" -m pip install --upgrade pip
"%~dp0env\Scripts\pip.exe" install -r "%~dp0requirements.txt"

:: 4. Buat folder notebooks jika belum ada
if not exist "%~dp0notebooks" (
    mkdir "%~dp0notebooks"
)

echo.
echo ========================================================
echo [3/3] SETUP SELESAI!
echo ========================================================
echo Langkah selanjutnya untuk temanmu:
echo 1. Pastikan Java JDK (17 atau 21) sudah terinstall.
echo 2. Cek config\env.cmd, pastikan JAVA_HOME mengarah ke folder JDK di PC-mu.
echo 3. Atur IP Radmin Master di config\env.cmd.
echo 4. Jalankan start-worker.cmd atau start-master.cmd!
echo ========================================================
pause
