@echo off
rem Open this project in the Godot 4.7.2 editor.
rem Engine path resolution lives in env.cmd (env var GODOT_BIN first).
call "%~dp0env.cmd"
if errorlevel 1 (
  pause
  exit /b 1
)
start "" "%GODOT_BIN%" --path "%~dp0." -e
