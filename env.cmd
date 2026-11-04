@echo off
rem ===========================================================
rem  Godot dual-target template - environment probe
rem  Called by the other scripts. Nothing here is machine specific:
rem  env var  >  known layout on this machine  >  PATH
rem  Recognised vars: GODOT_BIN JAVA_HOME ANDROID_HOME DEBUG_KEYSTORE
rem ===========================================================

rem ---------- engine ----------
if not defined GODOT_BIN if exist "C:\Tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe" set "GODOT_BIN=C:\Tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_BIN if exist "%USERPROFILE%\godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_BIN=%USERPROFILE%\godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_BIN for /f "delims=" %%i in ('where godot 2^>nul') do if not defined GODOT_BIN set "GODOT_BIN=%%i"
if not defined GODOT_BIN (
  echo [x] Godot 4.7.2 not found.
  echo     Set GODOT_BIN to Godot_v4.7.2-stable_win64.exe, or put the engine in
  echo     C:\Tools\Godot-4.7.2\ or %%USERPROFILE%%\godot\
  exit /b 1
)
set "GODOT_CONSOLE=%GODOT_BIN:_win64.exe=_win64_console.exe%"
if not exist "%GODOT_CONSOLE%" set "GODOT_CONSOLE=%GODOT_BIN%"

rem ---------- JDK ----------
if not defined JAVA_HOME if exist "%USERPROFILE%\scoop\apps\openjdk21\current\bin\java.exe" set "JAVA_HOME=%USERPROFILE%\scoop\apps\openjdk21\current"
if not defined JAVA_HOME if exist "%USERPROFILE%\godot\jdk-17.0.20.1+1\bin\java.exe" set "JAVA_HOME=%USERPROFILE%\godot\jdk-17.0.20.1+1"
if not defined JAVA_HOME for /d %%d in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do if not defined JAVA_HOME set "JAVA_HOME=%%d"
if not defined JAVA_HOME for /d %%d in ("C:\Program Files\Java\jdk-17*") do if not defined JAVA_HOME set "JAVA_HOME=%%d"

rem ---------- Android SDK ----------
if not defined ANDROID_HOME if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools" set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
if not defined ANDROID_HOME if exist "%USERPROFILE%\godot\android-sdk\platform-tools" set "ANDROID_HOME=%USERPROFILE%\godot\android-sdk"
if defined ANDROID_HOME set "ANDROID_SDK_ROOT=%ANDROID_HOME%"

rem ---------- debug keystore ----------
if not defined DEBUG_KEYSTORE if exist "%USERPROFILE%\.android\debug.keystore" set "DEBUG_KEYSTORE=%USERPROFILE%\.android\debug.keystore"
if not defined DEBUG_KEYSTORE if exist "%APPDATA%\Godot\keystores\debug.keystore" set "DEBUG_KEYSTORE=%APPDATA%\Godot\keystores\debug.keystore"

rem ---------- PATH ----------
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"
if defined ANDROID_HOME set "PATH=%ANDROID_HOME%\platform-tools;%PATH%"

rem ---------- report ----------
echo [env] engine   %GODOT_BIN%
if defined JAVA_HOME (echo [env] jdk      %JAVA_HOME%) else (echo [!] JDK 17+ not found, Android export will fail)
if defined ANDROID_HOME (echo [env] sdk      %ANDROID_HOME%) else (echo [!] Android SDK not found, Android export will fail)
if defined DEBUG_KEYSTORE (echo [env] keystore %DEBUG_KEYSTORE%) else (echo [!] debug keystore not found, Android export will fail)

exit /b 0
