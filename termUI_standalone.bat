@echo off
REM termUI Standalone - Single EXE distribution
REM This batch file wraps the PowerShell script for standalone execution
REM Usage: termUI.exe [--version|--changelog|--check-update|--update]

setlocal enabledelayedexpansion

REM Get script directory
set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%termUI-standalone.ps1

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo [ERROR] termUI-standalone.ps1 not found
    echo Please ensure termUI-standalone.ps1 is in the same directory as this EXE
    pause
    exit /b 1
)

REM Pass all arguments to PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
exit /b %ERRORLEVEL%
