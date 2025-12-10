@echo off
REM Test Program Launcher - Runs test_print_program.ps1

set "ScriptDir=%~dp0"
cd /d "%ScriptDir%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ScriptDir%test_print_program.ps1"
exit /b %ERRORLEVEL%
