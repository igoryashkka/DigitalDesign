@echo off
setlocal enabledelayedexpansion

set CLEAN_FLAG=0
set BUILD_FLAG=0
set COMPILE_SW=0
set MODE=tcl

:parse
if "%~1"=="" goto parsedone
if "%~1"=="-cln"        ( set CLEAN_FLAG=1 & shift & goto parse )
if "%~1"=="-mode"       ( set MODE=%~2 & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )
if "%~1"=="-m"          ( set MODE=%~2 & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )
if "%~1"=="-sw"         ( set COMPILE_SW=1 & shift & goto parse )
if "%~1"=="-swftware"   ( set COMPILE_SW=1 & shift & goto parse )
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

if %BUILD_FLAG%==1 (
  pushd project
  call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\build.tcl"
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

if %COMPILE_SW%==1 (
  pushd project
  call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\bd_creation.tcl"
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

endlocal
