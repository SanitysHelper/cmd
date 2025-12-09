@echo off
REM Settings Manager Launcher
REM Orchestrates execution of Manage-Settings.ps1

setlocal enabledelayedexpansion

set "ScriptDir=%~dp0"
set "PS1Script=%ScriptDir%Manage-Settings.ps1"
set "ReadmeFile=%ScriptDir%README.md"

:: Check if README exists, if not create it
if not exist "%ReadmeFile%" (
    echo [INFO] Generating README.md...
    echo # Settings Manager > "%ReadmeFile%"
    echo. >> "%ReadmeFile%"
    echo Interactive settings management tool for cmd workspace. >> "%ReadmeFile%"
    echo Run run.bat to view, edit, and add configuration settings. >> "%ReadmeFile%"
    echo [INFO] README.md created.
)

:: Launch PowerShell script
echo [INFO] Starting Settings Manager...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1Script%"
set EXITCODE=%ERRORLEVEL%

if %EXITCODE% NEQ 0 (
    echo [WARN] Settings Manager exited with code %EXITCODE%.
)

exit /b 0
