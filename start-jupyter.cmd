@echo off
title Jupyter Notebook - Spark Environment
call "%~dp0config\env.cmd"

echo.
echo ========================================================
echo   MENJALANKAN JUPYTER NOTEBOOK
echo ========================================================
echo   Direktori Notebook: %SPARK_BASE%\notebooks
echo   Silakan COPY tautan URL (http://127.0.0.1:8888/tree?token=...)
echo   ke Browser kamu jika tidak terbuka otomatis!
echo ========================================================
echo.

cd /d "%SPARK_BASE%\notebooks"
"%VENV_DIR%\Scripts\jupyter-notebook.exe" --ip=0.0.0.0 --port=8888 --no-browser
pause
