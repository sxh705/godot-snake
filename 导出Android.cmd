@echo off
rem ===========================================================
rem  Export a debug APK to build\android\SnakeBite.apk
rem  Double click to run: the console window stays open when done,
rem  so the whole Gradle log is readable and copyable.
rem  Needs JDK 17+, Android SDK, a debug keystore, and the aar files
rem  under android\build\libs (see README, they are not in git).
rem  Set EXPORT_VERBOSE=1 before running for Godot --verbose output.
rem ===========================================================
title SnakeBite - export Android
cd /d "%~dp0"
rem  /nopause : run unattended, do not wait for a key press at the end
if /i "%~1"=="/nopause" set "NOPAUSE=1"
call "%~dp0env.cmd"
if errorlevel 1 goto :fail

if not defined ANDROID_HOME (
  echo [x] Android SDK not found. Set ANDROID_HOME and run again.
  goto :fail
)
if not exist "android\build\libs\debug" (
  echo [x] android\build\libs is missing the Godot aar files.
  echo     In the editor: Project ^> Install Android Build Template
  goto :fail
)
findstr /i /c:".keystore" export_presets.cfg >nul 2>&1
if errorlevel 1 (
  echo [x] export_presets.cfg has no debug keystore path. Run setup.cmd once.
  goto :fail
)

if not exist "build" mkdir "build"
if not exist "build\android" mkdir "build\android"
if exist "build\android\SnakeBite.apk" del /q "build\android\SnakeBite.apk" >nul 2>&1

echo ==================================================================
echo   Android export   debug APK, single arm64-v8a
echo ==================================================================
echo   project   %~dp0
echo   engine    %GODOT_BIN%
echo   jdk       %JAVA_HOME%
echo   sdk       %ANDROID_HOME%
echo   keystore  %DEBUG_KEYSTORE%
echo   started   %DATE% %TIME%
echo.
"%GODOT_CONSOLE%" --version 2>nul
echo.

set "GODOT_VERBOSE="
if defined EXPORT_VERBOSE set "GODOT_VERBOSE=--verbose"

echo ------------------------------------------------------------------
echo   Running Godot export, then Gradle. Output starts below.
echo   The window can look frozen for 1 to 3 minutes: Gradle prints
echo   nothing while it resolves dependencies. The first run also
echo   downloads gradle itself, so 3 to 6 minutes total is normal.
echo ------------------------------------------------------------------
echo.

"%GODOT_CONSOLE%" %GODOT_VERBOSE% --headless --path "%~dp0." --export-debug "Android" "build/android/SnakeBite.apk"
set "RC=%ERRORLEVEL%"

echo.
echo ------------------------------------------------------------------
if exist "build\android\SnakeBite.apk" (
  echo [ok] build\android\SnakeBite.apk
  for %%f in ("build\android\SnakeBite.apk") do echo      size %%~zf bytes
  > "build\last-export.txt" echo android ok rc=%RC% file=build/android/SnakeBite.apk
) else (
  echo [x] export failed, godot exit code %RC%
  echo     Scroll up to the first line containing ERROR or FAILURE.
  echo     Gradle detail lives in android\build\build\
  > "build\last-export.txt" echo android fail rc=%RC%
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
