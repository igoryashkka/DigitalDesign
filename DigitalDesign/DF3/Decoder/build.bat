@echo off
setlocal enabledelayedexpansion


set CLEAN_FLAG=0
set BUILD_FLAG=0
set COMPILE_SW=0
set "MODE=tcl"
set "VHDL_STD="


:parse
if "%~1"=="" goto parsedone

if /I "%~1"=="-cln"        ( set CLEAN_FLAG=1 & shift & goto parse )
if /I "%~1"=="-mode"       ( set "MODE=%~2" & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )
if /I "%~1"=="-m"          ( set "MODE=%~2" & set BUILD_FLAG=1 & echo Selected %MODE% mode & shift & shift & goto parse )


rem Usage: -vt 2008   (forces VHDL-2008)
if /I "%~1"=="-vt"         ( set "VHDL_STD=%~2" & echo VHDL standard requested: %VHDL_STD% & shift & shift & goto parse )
if /I "%~1"=="--vhdl"      ( set "VHDL_STD=%~2" & echo VHDL standard requested: %VHDL_STD% & shift & shift & goto parse )
if /I "%~1"=="--vhdl-std"  ( set "VHDL_STD=%~2" & echo VHDL standard requested: %VHDL_STD% & shift & shift & goto parse )

rem ---- SW compile switch (kept as-is) ----
if /I "%~1"=="-sw"         ( set COMPILE_SW=1 & shift & goto parse )
if /I "%~1"=="-swftware"   ( set COMPILE_SW=1 & shift & goto parse )

echo Argument %~1 is not supported
shift
goto parse

:parsedone
rem If neither build nor clean was explicitly requested, default to build
if %BUILD_FLAG%==0 if %CLEAN_FLAG%==0 (
  echo Arguments not set. Building project
  set BUILD_FLAG=1
)

set "REPO_DIR=%CD%"


if %BUILD_FLAG%==1 (
  if not exist project mkdir project
) else if %CLEAN_FLAG%==1 (
  if exist project rmdir /s /q project
)


if %BUILD_FLAG%==1 (
  pushd project
  if "%VHDL_STD%"=="" (
    call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\build.tcl" -tclargs VHDL_STD ""
  ) else (
    call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\build.tcl" -tclargs VHDL_STD "%VHDL_STD%"
  )
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

if %COMPILE_SW%==1 (
  pushd project
  if "%VHDL_STD%"=="" (
    call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\bd_creation.tcl" -tclargs VHDL_STD ""
  ) else (
    call vivado -nojournal -nolog -mode %MODE% -source "%REPO_DIR%\scripts\bd_creation.tcl" -tclargs VHDL_STD "%VHDL_STD%"
  )
  if errorlevel 1 ( popd & exit /b 1 )
  popd
)

endlocal
