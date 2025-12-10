@echo off
REM termUI Standalone Launcher Batch
REM Single file distribution - downloads and runs termUI from GitHub
REM Can be renamed to termUI.exe and run as executable

setlocal enabledelayedexpansion

REM Get the PowerShell script path (should be in same directory as this batch)
set "BATCH_DIR=%~dp0"
set "PS_SCRIPT=%BATCH_DIR%termUI-standalone.ps1"

REM If PS1 doesn't exist locally, create it inline
if not exist "%PS_SCRIPT%" (
    echo Creating termUI standalone launcher...
    (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SanitysHelper/cmd/main/termUI-standalone.ps1' -OutFile '%PS_SCRIPT%' -UseBasicParsing"
    )
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to download termUI-standalone.ps1
        exit /b 1
    )
)

REM Execute the PowerShell script with all passed arguments
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
exit /b !ERRORLEVEL!
