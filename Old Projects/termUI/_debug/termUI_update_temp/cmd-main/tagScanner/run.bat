@echo off
setlocal

rem === Get this batch file's directory ===
set "SCRIPT_DIR=%~dp0"

rem === Move any backups to _debug directory on first run ===
set "DEBUG_DIR=%SCRIPT_DIR%_debug"
set "DEBUG_BACKUPS=%DEBUG_DIR%\backups"

if not exist "%DEBUG_DIR%" mkdir "%DEBUG_DIR%"

if exist "%SCRIPT_DIR%backups" (
    if not exist "%DEBUG_BACKUPS%" (
        mkdir "%DEBUG_BACKUPS%" 2>nul
        xcopy "%SCRIPT_DIR%backups\*" "%DEBUG_BACKUPS%\" /E /Y >nul 2>&1
        rmdir /s /q "%SCRIPT_DIR%backups" >nul 2>&1
    )
)

rem === Find the first .ps1 file in the same folder ===
for %%F in ("%SCRIPT_DIR%*.ps1") do (
    set "PS1_FILE=%%~fF"
    goto :found
)

echo No .ps1 file found in "%SCRIPT_DIR%".
pause
exit /b

:found
echo Running PowerShell script: %PS1_FILE%
echo.

rem === Launch PowerShell, allow scripts, keep window open ===
powershell -NoExit -ExecutionPolicy Bypass -File "%PS1_FILE%"

endlocal
exit /b
