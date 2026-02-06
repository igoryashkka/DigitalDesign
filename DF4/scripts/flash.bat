@echo off
setlocal

set REPO_DIR=%~dp0..
set BIT_PATH=%~1
set HW_SERVER=%~2
set HW_TARGET=%~3
set DEVICE_NAME=%~4

pushd "%REPO_DIR%\project"
call vivado -nojournal -nolog -mode tcl -source "%REPO_DIR%\scripts\flash.tcl" -tclargs "%BIT_PATH%" "%HW_SERVER%" "%HW_TARGET%" "%DEVICE_NAME%"
if errorlevel 1 ( popd & exit /b 1 )
popd

endlocal
