@echo off
setlocal
set SCRIPT_DIR=%~dp0
set PROJ_ROOT=%SCRIPT_DIR%..
set PROJ_DIR=%PROJ_ROOT%\vivado_project
for %%I in ("%PROJ_ROOT%\\..") do set REPO_ROOT=%%~fI

rem Args: 1=action (sim|elab|clean), 2=mode (gui|tcl), 3=testname, 4=IMG_FILE path
set ACTION=%1
if "%ACTION%"=="" set ACTION=sim

set SIM_MODE=%2
if "%SIM_MODE%"=="" set SIM_MODE=gui

set TESTNAME=%3
if "%TESTNAME%"=="" set TESTNAME=random_uvm_test

set IMG_FILE_ARG=%4

rem If the second argument is not a known mode, treat it as the test name and default mode to GUI.
if /I not "%SIM_MODE%"=="gui" if /I not "%SIM_MODE%"=="tcl" (
  if "%TESTNAME%"=="random_uvm_test" (
    set "TESTNAME=%SIM_MODE%"
    set "SIM_MODE=gui"
  )
)

rem PowerShell may split +UVM_TESTNAME=foo into two args (+UVM_TESTNAME, foo). Rejoin and leave IMG unset.
if /I "%TESTNAME%"=="+UVM_TESTNAME" if not "%IMG_FILE_ARG%"=="" (
  set "TESTNAME=%TESTNAME%=%IMG_FILE_ARG%"
  set "IMG_FILE_ARG="
)

if /I "%ACTION%"=="clean" (
  echo Cleaning Vivado-generated outputs...
  if exist "%PROJ_DIR%" rmdir /s /q "%PROJ_DIR%"
  if exist "%PROJ_ROOT%\xsim.dir" rmdir /s /q "%PROJ_ROOT%\xsim.dir"
  if exist "%PROJ_ROOT%\.Xil" rmdir /s /q "%PROJ_ROOT%\.Xil"
  for %%D in ("%SCRIPT_DIR%" "%PROJ_ROOT%" "%REPO_ROOT%") do (
    for %%F in ("%%~D\\vivado.jou" "%%~D\\vivado.log") do (
      if exist "%%~F" del /f /q "%%~F"
    )
    for %%P in ("%%~D\\*.jou" "%%~D\\*.jou.*" "%%~D\\*.log" "%%~D\\*.log.*") do (
      for %%X in (%%P) do if exist "%%~X" del /f /q "%%~X"
    )
  )
  echo Done.
  exit /b 0
)

echo Using test: %TESTNAME%
set "UVM_TESTNAME=%TESTNAME%"

if not "%IMG_FILE_ARG%"=="" (
  echo Using IMG_FILE: %IMG_FILE_ARG%
  set "IMG_FILE=%IMG_FILE_ARG%"
)

echo Running Vivado automation with action %ACTION% (mode=%SIM_MODE%)
vivado -mode batch -source "%SCRIPT_DIR%setup_vivado.tcl" -tclargs %ACTION% %SIM_MODE%

if %ERRORLEVEL% NEQ 0 (
  echo Vivado automation failed with exit code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo Vivado automation complete.
endlocal
