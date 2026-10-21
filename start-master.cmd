@echo off
title Spark Master Daemon
call "%~dp0config\env.cmd"

echo.
echo ========================================================
echo   MENJALANKAN SPARK MASTER (PC MASTER)
echo ========================================================
echo   Web UI Master : http://localhost:%MASTER_WEBUI_PORT%
echo   Port RPC Spark: %MASTER_PORT%
echo.
echo   Pastikan teman-teman Worker terhubung ke URL Master ini!
echo   (Jika pakai Radmin VPN, bagikan IP Radmin PC Master)
echo ========================================================
echo.

set HOST_ARG=
if not "%LOCAL_HOST_IP%"=="" (
    set HOST_ARG=--host %LOCAL_HOST_IP%
)

call "%SPARK_HOME%\bin\spark-class2.cmd" org.apache.spark.deploy.master.Master %HOST_ARG% --port %MASTER_PORT% --webui-port %MASTER_WEBUI_PORT%
pause
