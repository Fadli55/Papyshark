@echo off
:: ========================================================
:: KONFIGURASI ENVIRONMENT SPARK & CLUSTER
:: ========================================================

:: 1. Tentukan IP Master (Jika pakai Radmin VPN, masukkan IP Radmin milik PC Master)
:: Contoh: set MASTER_IP=26.x.x.x
set MASTER_IP=127.0.0.1
set MASTER_PORT=7077
set MASTER_WEBUI_PORT=8080

:: 2. Port untuk Worker UI (hanya dibuka di PC Worker)
set WORKER_WEBUI_PORT=8081

:: 3. IP PC ini sendiri (Opsional: jika pakai Radmin, masukkan IP Radmin PC ini)
:: Kosongkan jika ingin Spark mendeteksi IP network secara otomatis
set LOCAL_HOST_IP=

:: 4. Path Java JDK (Otomatis prioritaskan JDK lokal dari setup.cmd atau Program Files)
set "SPARK_BASE=%~dp0.."

if exist "%SPARK_BASE%\jdk-21\bin\java.exe" (
    set "JAVA_HOME=%SPARK_BASE%\jdk-21"
) else if exist "C:\Program Files\Java\jdk-21.0.12" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12"
) else if exist "C:\Program Files\Java\jdk-21" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-21"
) else if exist "C:\Program Files\Java\jdk-17" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-17"
) else (
    set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12"
)
set "PATH=%JAVA_HOME%\bin;%PATH%"

:: 5. Path Hadoop Winutils
set "HADOOP_HOME=%SPARK_BASE%\hadoop"
set "PATH=%HADOOP_HOME%\bin;%PATH%"

:: 6. Path Virtual Environment Python
set "VENV_DIR=%SPARK_BASE%\env"
set "SPARK_HOME=%VENV_DIR%\Lib\site-packages\pyspark"
set "PATH=%VENV_DIR%\Scripts;%PATH%"
set "PYSPARK_PYTHON=%VENV_DIR%\Scripts\python.exe"
set "PYSPARK_DRIVER_PYTHON=%VENV_DIR%\Scripts\python.exe"

echo [CONFIG] Environment Spark terkonfigurasi.
