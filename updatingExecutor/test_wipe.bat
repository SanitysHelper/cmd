@echo off
REM Test script for wipe option
setlocal

cd /d "C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor"

echo Testing WIPE option...
echo.

REM Create a marker file in run_space first
echo test marker > run_space\test_marker.txt

echo Before wipe:
dir run_space | find ".txt"

echo.
echo Sending W command...
(echo W) | run.bat

echo.
echo After wipe:
if exist run_space\test_marker.txt (
    echo [ERROR] Marker file still exists!
) else (
    echo [OK] Marker file was deleted.
)

endlocal
