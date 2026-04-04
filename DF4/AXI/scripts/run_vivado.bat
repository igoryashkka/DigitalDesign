@echo off
setlocal
set SCRIPT_DIR=%~dp0
set PROJ_ROOT=%SCRIPT_DIR%..
set PROJ_DIR=%PROJ_ROOT%\vivado_project
for %%I in ("%PROJ_ROOT%\..\..") do set REPO_ROOT=%%~fI

rem Args: 1=action (sim|elab|clean), 2=mode (gui|tcl), 3=testname
set ACTION=%1
if "%ACTION%"=="" set ACTION=sim

set ARG2=%2
set ARG3=%3

rem Parse args:
rem - If arg2 is gui/tcl: mode=arg2, test=arg3 (or default)
rem - Otherwise: mode=gui (default), test=arg2 (or default)
if /I "%ARG2%"=="gui" (
  set "SIM_MODE=gui"
  set "TESTNAME=%ARG3%"
) else if /I "%ARG2%"=="tcl" (
  set "SIM_MODE=tcl"
  set "TESTNAME=%ARG3%"
) else (
  set "SIM_MODE=gui"
  set "TESTNAME=%ARG2%"
)

if "%TESTNAME%"=="" set TESTNAME=direct_uvm_test

if /I "%ACTION%"=="clean" (
  echo Cleaning Vivado-generated outputs...
  if exist "%PROJ_DIR%" rmdir /s /q "%PROJ_DIR%"
  if exist "%PROJ_ROOT%\xsim.dir" rmdir /s /q "%PROJ_ROOT%\xsim.dir"
  if exist "%PROJ_ROOT%\.Xil" rmdir /s /q "%PROJ_ROOT%\.Xil"
  for %%D in ("%SCRIPT_DIR%" "%PROJ_ROOT%" "%REPO_ROOT%") do (
    for %%F in ("%%~D\vivado.jou" "%%~D\vivado.log") do (
      if exist "%%~F" del /f /q "%%~F"
    )
    for %%P in ("%%~D\*.jou" "%%~D\*.jou.*" "%%~D\*.log" "%%~D\*.log.*") do (
      for %%X in (%%P) do if exist "%%~X" del /f /q "%%~X"
    )
  )
  echo Done.
  exit /b 0
)

echo Using test: %TESTNAME%
set "UVM_TESTNAME=%TESTNAME%"

echo Running Vivado automation with action %ACTION% (mode=%SIM_MODE%)
vivado -mode batch -source "%SCRIPT_DIR%setup_vivado.tcl" -tclargs %ACTION% %SIM_MODE%

if %ERRORLEVEL% NEQ 0 (
  echo Vivado automation failed with exit code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo Vivado automation complete.
endlocal
