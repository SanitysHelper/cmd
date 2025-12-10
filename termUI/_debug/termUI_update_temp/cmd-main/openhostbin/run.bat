@echo off
setlocal
set "ScriptDir=%~dp0"

:: Use -ResetPassword to re-prompt and update stored password
:: Use -SkipConnect for dry-run/testing without hitting remote host

powershell -NoLogo -ExecutionPolicy Bypass -File "%ScriptDir%connect.ps1" %*
set "ExitCode=%ERRORLEVEL%"
if not "%ExitCode%"=="0" (
    echo [WARN] SSH exited with %ExitCode%.
)
exit /b %ExitCode%
