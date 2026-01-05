@echo off
setlocal
set SCRIPT_DIR=%~dp0
set PROJ_ROOT=%SCRIPT_DIR%..
set PROJ_DIR=%PROJ_ROOT%\vivado_project

set ACTION=%1
if "%ACTION%"=="" set ACTION=sim

set SIM_MODE=%2
if "%SIM_MODE%"=="" set SIM_MODE=gui

set CLEAN=%3

if /I "%CLEAN%"=="clean" (
  echo Cleaning Vivado-generated outputs...
  if exist "%PROJ_DIR%" rmdir /s /q "%PROJ_DIR%"
  if exist "%PROJ_ROOT%\xsim.dir" rmdir /s /q "%PROJ_ROOT%\xsim.dir"
  if exist "%PROJ_ROOT%\.Xil" rmdir /s /q "%PROJ_ROOT%\.Xil"
  if exist "%SCRIPT_DIR%vivado.jou" del /f /q "%SCRIPT_DIR%vivado.jou"
  if exist "%SCRIPT_DIR%vivado.log" del /f /q "%SCRIPT_DIR%vivado.log"
)

echo Running Vivado automation with action %ACTION% (mode=%SIM_MODE%)
vivado -mode batch -source "%SCRIPT_DIR%setup_vivado.tcl" -tclargs %ACTION% %SIM_MODE%

if %ERRORLEVEL% NEQ 0 (
  echo Vivado automation failed with exit code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo Vivado automation complete.
endlocal
