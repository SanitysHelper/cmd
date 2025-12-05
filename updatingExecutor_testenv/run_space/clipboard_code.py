@echo off
setlocal EnableDelayedExpansion
title Language Test Runner

echo ======================================================
echo Running All Language Tests
echo ======================================================
echo.

set "TEST_DIR=%~dp0"
set "LOG_FILE=%TEST_DIR%log\test_results.log"

REM Create log directory
if not exist "%TEST_DIR%log" mkdir "%TEST_DIR%log"

echo Test Run: %DATE% %TIME% > "%LOG_FILE%"
echo ====================================== >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo [TEST 1/6] Python...
python "%TEST_DIR%test_python.py" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] Python) else (echo [FAIL] Python)
echo. >> "%LOG_FILE%"
echo.

echo [TEST 2/6] PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEST_DIR%test_powershell.ps1" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] PowerShell) else (echo [FAIL] PowerShell)
echo. >> "%LOG_FILE%"
echo.

echo [TEST 3/6] Batch...
call "%TEST_DIR%test_batch.bat" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] Batch) else (echo [FAIL] Batch)
echo. >> "%LOG_FILE%"
echo.

echo [TEST 4/6] JavaScript...
node "%TEST_DIR%test_javascript.js" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] JavaScript) else (echo [FAIL] JavaScript)
echo. >> "%LOG_FILE%"
echo.

echo [TEST 5/6] Ruby...
ruby "%TEST_DIR%test_ruby.rb" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] Ruby) else (echo [FAIL] Ruby)
echo. >> "%LOG_FILE%"
echo.

echo [TEST 6/6] Lua...
lua "%TEST_DIR%test_lua.lua" >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! equ 0 (echo [PASS] Lua) else (echo [FAIL] Lua)
echo. >> "%LOG_FILE%"
echo.

echo ======================================================
echo Test run complete. Log: log\test_results.log
echo ======================================================
pause

