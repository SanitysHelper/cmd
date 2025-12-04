@echo off
setlocal

rem === Get this batch file’s directory ===
set "SCRIPT_DIR=%~dp0"

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