@echo off
setlocal
set SCRIPT_DIR=%~dp0
set ACTION=%1
if "%ACTION%"=="" set ACTION=sim

echo Running Vivado automation with action %ACTION%
vivado -mode batch -source "%SCRIPT_DIR%setup_vivado.tcl" -tclargs %ACTION%

if %ERRORLEVEL% NEQ 0 (
  echo Vivado automation failed with exit code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo Vivado automation complete.
endlocal
