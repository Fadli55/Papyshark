@echo off
title Setup Otomatis Spark Environment
cd /d "%~dp0"

echo Menjalankan proses setup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

if errorlevel 1 (
    echo.
    echo Ada kendala saat menjalankan setup.
    pause
)
