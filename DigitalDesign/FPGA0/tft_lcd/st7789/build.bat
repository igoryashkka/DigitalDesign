@echo off
setlocal enabledelayedexpansion

set BUILD_FLAG=0
set CLEAN_FLAG=0
set SYNTH_FLAG=0
set IMPL_FLAG=0
set BIT_FLAG=0
set MODE=batch

:parse
if "%~1"=="" goto parsedone
if /I "%~1"=="-cln"  ( set CLEAN_FLAG=1 & shift & goto parse )
if /I "%~1"=="-mode" ( set MODE=%~2 & shift & shift & goto parse )
if /I "%~1"=="-m"    ( set MODE=%~2 & shift & shift & goto parse )
if /I "%~1"=="-syn"  ( set SYNTH_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if /I "%~1"=="-impl" ( set SYNTH_FLAG=1 & set IMPL_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if /I "%~1"=="-bit"  ( set SYNTH_FLAG=1 & set IMPL_FLAG=1 & set BIT_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if /I "%~1"=="-all"  ( set SYNTH_FLAG=1 & set IMPL_FLAG=1 & set BIT_FLAG=1 & set BUILD_FLAG=1 & shift & goto parse )
if /I "%~1"=="-proj" ( set BUILD_FLAG=1 & shift & goto parse )
echo Argument %~1 is not supported
shift
goto parse

:parsedone
if %BUILD_FLAG%==0 if %CLEAN_FLAG%==0 (
  echo Arguments not set. Running full build: synth+impl+bit.
  set SYNTH_FLAG=1
  set IMPL_FLAG=1
  set BIT_FLAG=1
  set BUILD_FLAG=1
)

set REPO_DIR=%~dp0
if "%REPO_DIR:~-1%"=="\" set REPO_DIR=%REPO_DIR:~0,-1%

if %CLEAN_FLAG%==1 (
  call vivado -nojournal -nolog -mode batch -source "%REPO_DIR%\scripts\run_vivado.tcl" -tclargs clean
  if errorlevel 1 exit /b 1
)

if %BUILD_FLAG%==1 (
  call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\run_vivado.tcl" -tclargs build %SYNTH_FLAG% %IMPL_FLAG% %BIT_FLAG%
  if errorlevel 1 exit /b 1
)

endlocal
