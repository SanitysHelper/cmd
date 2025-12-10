@echo off
REM termUI Installer - Main Launcher
REM Compiles (if needed) and runs the installer

setlocal

echo =============================================
echo   termUI Installer
echo =============================================
echo.

REM Check if executable exists
if not exist "bin\termUIInstaller.exe" (
    echo [INFO] Executable not found, compiling...
    echo.
    call compile.bat
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Compilation failed!
        pause
        exit /b 1
    )
    echo.
)

REM Create logs directory if it doesn't exist
if not exist "_debug\logs" mkdir "_debug\logs"

REM Run the installer
echo [INFO] Launching termUI Installer...
echo.
bin\termUIInstaller.exe %*

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

echo.
if %EXIT_CODE% EQU 0 (
    echo [INFO] Installer completed successfully
) else (
    echo [WARN] Installer exited with code: %EXIT_CODE%
)

echo.
echo Check _debug\logs\installer.log for details
echo.

exit /b %EXIT_CODE%
