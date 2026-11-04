@echo off
rem ===========================================================
rem  Export the Windows build to build\windows\SnakeBite.exe
rem  Double click to run: the console window stays open when done,
rem  so the whole log is readable and copyable.
rem  Set EXPORT_VERBOSE=1 before running for Godot --verbose output.
rem ===========================================================
title SnakeBite - export Windows
cd /d "%~dp0"
rem  /nopause : run unattended, do not wait for a key press at the end
if /i "%~1"=="/nopause" set "NOPAUSE=1"
call "%~dp0env.cmd"
if errorlevel 1 goto :fail

if not exist "build" mkdir "build"
if not exist "build\windows" mkdir "build\windows"
if exist "build\windows\SnakeBite.exe" del /q "build\windows\SnakeBite.exe" >nul 2>&1

echo ==================================================================
echo   Windows export
echo ==================================================================
echo   project   %~dp0
echo   engine    %GODOT_BIN%
echo   started   %DATE% %TIME%
echo.
"%GODOT_CONSOLE%" --version 2>nul
echo.

set "GODOT_VERBOSE="
if defined EXPORT_VERBOSE set "GODOT_VERBOSE=--verbose"

echo ------------------------------------------------------------------
echo   Running Godot export. Output starts below.
echo   This target does not use Gradle: 5 to 15 seconds is normal.
echo ------------------------------------------------------------------
echo.

"%GODOT_CONSOLE%" %GODOT_VERBOSE% --headless --path "%~dp0." --export-release "Windows Desktop" "build/windows/SnakeBite.exe"
set "RC=%ERRORLEVEL%"

echo.
echo ------------------------------------------------------------------
if exist "build\windows\SnakeBite.exe" (
  echo [ok] build\windows\SnakeBite.exe
  for %%f in ("build\windows\SnakeBite.exe") do echo      size %%~zf bytes
  > "build\last-export.txt" echo windows ok rc=%RC% file=build/windows/SnakeBite.exe
) else (
  echo [x] export failed, godot exit code %RC%
  echo     Scroll up to the first line containing ERROR.
  > "build\last-export.txt" echo windows fail rc=%RC%
)
echo   finished  %DATE% %TIME%
echo ------------------------------------------------------------------
echo.
echo Press any key to close this window.
if not defined NOPAUSE pause >nul
exit /b 0

:fail
echo.
echo Setup failed, see the [x] line above. Window stays open.
if not defined NOPAUSE pause >nul
exit /b 1
