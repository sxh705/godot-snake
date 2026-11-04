@echo off
rem ===========================================================
rem  One-time setup for THIS machine.
rem  Probes the toolchain and writes the local debug-keystore path
rem  into export_presets.cfg (that single line cannot be shared
rem  between machines). Run it once after cloning, then build.
rem ===========================================================
cd /d "%~dp0"

call "%~dp0env.cmd"
if errorlevel 1 goto :fail

echo.
echo ---- versions ----
"%GODOT_CONSOLE%" --version
if defined JAVA_HOME (java -version 2>&1 | findstr /i "version") else (echo [!] JDK not found, skipped)

echo.
if not defined DEBUG_KEYSTORE goto :nokeystore

rem ---------- patch keystore/debug in export_presets.cfg ----------
set "PS1=%TEMP%\godot-setks.ps1"
> "%PS1%"  echo $p = '%~dp0export_presets.cfg'
>>"%PS1%"  echo $k = $args[0] -replace '\\', '/'
>>"%PS1%"  echo $q = [char]34
>>"%PS1%"  echo $c = Get-Content -Raw -LiteralPath $p
>>"%PS1%"  echo $r = 'keystore/debug=' + $q + $k + $q
>>"%PS1%"  echo $c = $c -replace 'keystore/debug=.*', $r
>>"%PS1%"  echo Set-Content -NoNewline -LiteralPath $p -Value $c
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%DEBUG_KEYSTORE%" >nul 2>&1
del "%PS1%" >nul 2>&1

findstr /b /c:"keystore/debug=" export_presets.cfg | findstr /i /c:".keystore" >nul 2>&1
if errorlevel 1 (
  echo [x] could not patch export_presets.cfg. Set this line by hand:
  echo     keystore/debug="%DEBUG_KEYSTORE:\=/%"
) else (
  echo [ok] export_presets.cfg -^> %DEBUG_KEYSTORE:\=/%
  echo      This line is per machine. Keep the local change, do not commit it.
)
goto :done

:nokeystore
echo [!] No debug keystore found, Android export will fail. Create one with:
echo     keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12

:done
echo.
echo Next: run the launcher .cmd in this folder to open the editor or export.
pause
exit /b 0

:fail
echo [x] environment incomplete - fix the items above and run again.
pause
exit /b 1
