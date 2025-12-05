@echo off
REM Final verification test for boot menu with wipe functionality
setlocal

cd /d "C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor"

echo.
echo ====================================
echo  Final Boot Menu Verification Test
echo ====================================
echo.

echo Step 1: Check initial state
echo Files in run_space:
for /F "delims=" %%F in ('dir /b run_space 2^>nul ^| find /c /v ""') do set count=%%F
echo  Total: %count% files
echo.

echo Step 2: Wipe run_space
(echo W) | run.bat >nul 2>&1
echo Files after wipe:
for /F "delims=" %%F in ('dir /b run_space 2^>nul ^| find /c /v ""') do set count=%%F
echo  Total: %count% files
if %count% equ 0 (
    echo  [OK] Run_space is clean
) else (
    echo  [ERROR] Run_space still has files!
)
echo.

echo Step 3: Continue and verify helpers restored
(echo Q) | run.bat >nul 2>&1
if exist run_space\read_clipboard.ps1 (
    echo [OK] Clipboard helper restored
) else (
    echo [ERROR] Clipboard helper missing
)
if exist run_space\strip_bom.bat (
    echo [OK] BOM stripper restored
) else (
    echo [ERROR] BOM stripper missing
)
echo.

echo ====================================
echo  Test Complete
echo ====================================

endlocal
