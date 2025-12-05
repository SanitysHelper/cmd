@REM runBackup[v1.6] - Testing Script for Updating Executor v1.6
@REM This script documents and executes tests for the Updating Executor
@REM Generated: December 5, 2025

@echo off
setlocal enabledelayedexpansion

set "SCRIPT_VERSION=1.6"
set "SCRIPT_NAME=runBackup[v%SCRIPT_VERSION%]"
set "TEST_DIR=%~dp0"
set "EXEC_PATH=%TEST_DIR%run.bat"

echo ========================================
echo %SCRIPT_NAME% - Testing Script
echo ========================================
echo Version: %SCRIPT_VERSION%
echo Test Directory: %TEST_DIR%
echo Executable: %EXEC_PATH%
echo.

REM Test 1: Verify executable exists
if not exist "%EXEC_PATH%" (
    echo [ERROR] Executable not found: %EXEC_PATH%
    exit /b 1
)
echo [✓] Executable found

REM Test 2: /W Wipe flag
echo.
echo [TEST] Running /W wipe flag...
call "%EXEC_PATH%" /W >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [✓] Wipe flag test passed (exit code 0)
) else (
    echo [✗] Wipe flag test failed (exit code %ERRORLEVEL%)
)

REM Test 3: Settings file exists
echo.
echo [TEST] Checking settings.ini...
if exist "%TEST_DIR%settings.ini" (
    echo [✓] Settings file found
    REM Count settings
    for /f %%L in ('findstr /c:^"^" "%TEST_DIR%settings.ini" 2^>nul') do set /a "SETTING_COUNT+=1"
    echo [INFO] Settings entries: !SETTING_COUNT!
) else (
    echo [✗] Settings file not found
)

REM Test 4: Documentation files
echo.
echo [TEST] Checking documentation...
for %%F in ("USER_GUIDE.md" "FINAL_SUMMARY.md" "TEST_REPORT.md") do (
    if exist "%TEST_DIR%%%~F" (
        echo [✓] %%~F found
    ) else (
        echo [✗] %%~F missing
    )
)

REM Test 5: Backup versions
echo.
echo [TEST] Checking version backups...
set "BACKUP_COUNT=0"
for %%F in ("%TEST_DIR%backups\run_v*.bat") do (
    set /a "BACKUP_COUNT+=1"
)
echo [INFO] Version backups: !BACKUP_COUNT!

REM Test 6: Run space structure
echo.
echo [TEST] Checking run_space directory...
if exist "%TEST_DIR%run_space" (
    echo [✓] run_space directory found
    if exist "%TEST_DIR%run_space\log" (
        echo [✓] log subdirectory found
    ) else (
        echo [✗] log subdirectory missing
    )
    if exist "%TEST_DIR%run_space\languages" (
        echo [✓] languages subdirectory found
    ) else (
        echo [✗] languages subdirectory missing
    )
) else (
    echo [✗] run_space directory missing
)

echo.
echo ========================================
echo [INFO] Testing complete
echo ========================================
echo.
echo Next steps:
echo 1. Run interactive mode: call "%EXEC_PATH%"
echo 2. Copy code to clipboard and wait for prompts
echo 3. Use timeout-based menu navigation (no manual input needed)
echo 4. Check logs in: %TEST_DIR%run_space\log\
echo.

endlocal
exit /b 0
