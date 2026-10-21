@echo off
title Spark Worker Daemon
call "%~dp0config\env.cmd"

echo.
echo ========================================================
echo   MENJALANKAN SPARK WORKER (PC WORKER)
echo ========================================================
echo   Target Master : spark://%MASTER_IP%:%MASTER_PORT%
echo   Worker Web UI : http://localhost:%WORKER_WEBUI_PORT%
echo.
echo   Pastikan config\env.cmd sudah diset dengan IP Master temanmu!
echo ========================================================
echo.

set HOST_ARG=
if not "%LOCAL_HOST_IP%"=="" (
    set HOST_ARG=--host %LOCAL_HOST_IP%
)

call "%SPARK_HOME%\bin\spark-class2.cmd" org.apache.spark.deploy.worker.Worker %HOST_ARG% --webui-port %WORKER_WEBUI_PORT% spark://%MASTER_IP%:%MASTER_PORT%
pause
