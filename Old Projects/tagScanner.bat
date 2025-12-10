@echo off
setlocal

:: =========================================================================
:: 1. SETUP PATHS
:: TargetFolder = Folder with same name as this script
:: LockFolder   = A temp folder to track running processes
:: =========================================================================
set "TargetFolder=%~dp0%~n0"
set "LockFolder=%TargetFolder%\_temp_locks"

:checkStatus
:: --- 2. Move to Target Folder ---
cd /d "%TargetFolder%"

:: --- 3. Check Status ---
if not exist "status.txt" (
    echo ❌ ERROR: status.txt missing in %TargetFolder%
    timeout /t 5 >nul
    goto :checkStatus
)

findstr /i "false" "status.txt" >nul
if %errorlevel% equ 0 goto :end

:: --- 4. PREPARE PARALLEL RUN ---
echo.
echo ✅ STATUS CLEAR: Launching all tasks simultaneously...

:: Create the temp lock folder (hide output if it exists)
if not exist "%LockFolder%" mkdir "%LockFolder%"

:: Loop through all .bat files
for %%f in (*.bat) do (
    :: Skip this script if it's inside the folder
    if /i not "%%f"=="%~nx0" (
        
        :: A. Create a "Lock File" for this specific script
        type nul > "%LockFolder%\%%~nxf.lock"
        
        :: B. Start the script in a NEW window (Parallel)
        :: The command runs the script, then deletes its lock file when done.
        echo Launching: %%f
        start "Running %%~nxf" cmd /c "call "%%f" & del "%LockFolder%\%%~nxf.lock"""
    )
)

:: --- 5. WAIT FOR ALL TASKS TO FINISH ---
echo.
echo ⏳ Waiting for all tasks to complete...

:WaitForTasks
:: Check if any .lock files still exist in the temp folder
if exist "%LockFolder%\*.lock" (
    :: Wait 1 second and check again
    timeout /t 1 >nul
    goto :WaitForTasks
)

:: Clean up the empty lock folder
rd "%LockFolder%" 2>nul

:: --- 6. RESTART LOOP ---
echo.
echo 🏁 All tasks finished. Waiting 5 seconds before re-checking status...
timeout /t 5 >nul
goto :checkStatus

:end
echo.
echo 🛑 STOP SIGNAL DETECTED ("false" in status.txt).
echo Script finished.
pause
exit /b