@echo off
setlocal

set REPO_DIR=%~dp0
if "%REPO_DIR:~-1%"=="\" set REPO_DIR=%REPO_DIR:~0,-1%

vivado -mode gui -source "%REPO_DIR%\scripts\run_vivado.tcl" -tclargs open
set RET=%ERRORLEVEL%

endlocal & exit /b %RET%
