@echo off
REM Quick test runner for tagScanner automated tests
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Run-Test.ps1" -TestFile test_read_artist.json -Verify
pause
