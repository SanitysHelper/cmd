@echo off
REM Compile CodeExecutor.ahk to EXE
REM This script requires AutoHotkey v2.0 to be installed

setlocal enabledelayedexpansion

echo [INFO] Checking for AutoHotkey v2.0...

REM Try common AutoHotkey installation paths
if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" (
    set "AHK_PATH=C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"
    echo [OK] Found AutoHotkey at: !AHK_PATH!
) else if exist "C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe" (
    set "AHK_PATH=C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe"
    echo [OK] Found AutoHotkey at: !AHK_PATH!
) else (
    echo [ERROR] AutoHotkey v2.0 not found!
    echo.
    echo To use this tool, please:
    echo 1. Download AutoHotkey v2.0 from https://www.autohotkey.com/
    echo 2. Install it to default location
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

echo.
echo [INFO] Attempting to compile CodeExecutor.ahk...

if not exist "CodeExecutor.ahk" (
    echo [ERROR] CodeExecutor.ahk not found in current directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

REM Compile using Ahk2Exe
if exist "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
    "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe" /in CodeExecutor.ahk /out CodeExecutor.exe
) else if exist "C:\Program Files (x86)\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
    "C:\Program Files (x86)\AutoHotkey\v2\Compiler\Ahk2Exe.exe" /in CodeExecutor.ahk /out CodeExecutor.exe
) else (
    echo [ERROR] Ahk2Exe compiler not found
    pause
    exit /b 1
)

if exist "CodeExecutor.exe" (
    echo.
    echo [SUCCESS] CodeExecutor.exe created successfully!
    echo Location: %CD%\CodeExecutor.exe
    echo.
    echo You can now run: CodeExecutor.exe
    pause
) else (
    echo [ERROR] Compilation failed
    pause
    exit /b 1
)
