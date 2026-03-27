@echo off
setlocal enabledelayedexpansion

set CLEAN_FLAG=0
set BUILD_FLAG=0
set COMPILE_SW=0
set SYNTH_FLAG=0
set IMPL_FLAG=0
set BIT_FLAG=0
set XSA_FLAG=0
set MODE=tcl

:parse
if "%~1"=="" goto parsedone
if "%~1"=="-cln"        ( set CLEAN_FLAG=1 & shift & goto parse )
if "%~1"=="-mode"       ( set MODE=%~2 & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )
if "%~1"=="-m"          ( set MODE=%~2 & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )
if "%~1"=="-sw"         ( set COMPILE_SW=1 & shift & goto parse )
if "%~1"=="-swftware"   ( set COMPILE_SW=1 & shift & goto parse )
if "%~1"=="-syn"        ( set SYNTH_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if "%~1"=="-impl"       ( set IMPL_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if "%~1"=="-bit"        ( set BIT_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if "%~1"=="-xsa"        ( set XSA_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if "%~1"=="-all"        ( set SYNTH_FLAG=1 & set IMPL_FLAG=1 & set BIT_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
echo Argument %~1 is not supported
shift
goto parse

:parsedone
if "%~0"=="" (
  rem no args check is tricky in cmd; assume if BUILD_FLAG=0 after parse then no args
)
if %BUILD_FLAG%==0 if %CLEAN_FLAG%==0 (
  echo Arguments not set. Building project
  set BUILD_FLAG=1
)

set REPO_DIR=%CD%

if %BUILD_FLAG%==1 (
  if not exist project mkdir project
) else if %CLEAN_FLAG%==1 (
  if exist project rmdir /s /q project
)

REM Check if synthesis, implementation, bitstream, or XSA flags are set
if %SYNTH_FLAG%==1 (
  set EXEC_SCRIPT=run.tcl
) else if %IMPL_FLAG%==1 (
  set EXEC_SCRIPT=run.tcl
) else if %BIT_FLAG%==1 (
  set EXEC_SCRIPT=run.tcl
) else if %XSA_FLAG%==1 (
  set EXEC_SCRIPT=run.tcl
) else (
  set EXEC_SCRIPT=build.tcl
)

if %BUILD_FLAG%==1 (
  pushd project
  call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\%EXEC_SCRIPT%" -tclargs %SYNTH_FLAG% %IMPL_FLAG% %BIT_FLAG% %XSA_FLAG%
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

if %COMPILE_SW%==1 (
  pushd project
  call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\bd_creation.tcl"
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

endlocal
