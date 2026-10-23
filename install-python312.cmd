@echo off
setlocal
title Install Python 3.12 Resmi Windows
echo ========================================================
echo   DOWNLOAD & INSTALL PYTHON 3.12.7 RESMI (WINDOWS)
echo ========================================================
echo Script ini akan mengunduh dan memasang Python 3.12.7
echo agar versi Python seragam satu kelompok.
echo ========================================================
echo.

set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "INSTALLER=%~dp0python-3.12.7-installer.exe"

echo [1/2] Mengunduh installer Python 3.12.7 (sekitar 25 MB)...
if exist "%INSTALLER%" del /f /q "%INSTALLER%"

curl.exe -L -C - --retry 5 --retry-delay 3 -o "%INSTALLER%" "%PY_URL%"
if not exist "%INSTALLER%" (
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%PY_URL%', '%INSTALLER%')"
)

if not exist "%INSTALLER%" (
    echo [ERROR] Gagal mengunduh installer.
    echo Silakan unduh manual dari browser: %PY_URL%
    pause
    exit /b 1
)

echo.
echo [2/2] Memasang Python 3.12 (Harap tunggu 30-60 detik)...
"%INSTALLER%" /passive InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_test=0

del /f /q "%INSTALLER%"

echo.
echo ========================================================
echo   [SUKSES] PYTHON 3.12 BERHASIL DIPASANG!
echo ========================================================
echo Langkah selanjutnya:
echo 1. HAPUS folder 'env' lama jika ada di laptopmu.
echo 2. Jalankan lagi setup.cmd agar env terbuat dengan Python 3.12.
echo ========================================================
pause
