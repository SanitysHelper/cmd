@echo off
REM Compile CodeExecutor.cs to standalone EXE
REM Requires .NET Framework (included with Windows)

setlocal enabledelayedexpansion

echo [INFO] Building Universal Code Executor...
echo.

REM Find C# compiler
set "CSC_PATH="

if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    echo [OK] Found C# compiler at: !CSC_PATH!
) else if exist "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    echo [OK] Found C# compiler at: !CSC_PATH!
) else (
    echo [ERROR] C# compiler not found!
    echo.
    echo This tool requires .NET Framework 4.0 or later, which is included with Windows.
    echo If you have a fresh Windows installation, you may need to enable .NET Framework:
    echo - Go to Control Panel ^> Programs ^> Turn Windows features on or off
    echo - Enable ".NET Framework 3.5" and ".NET Framework 4.8 Advanced Services"
    echo.
    pause
    exit /b 1
)

echo.
echo [INFO] Compiling CodeExecutor.cs...
echo.

if not exist "CodeExecutor.cs" (
    echo [ERROR] CodeExecutor.cs not found in current directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

"!CSC_PATH!" /target:winexe /out:CodeExecutor.exe CodeExecutor.cs 2>&1

if exist "CodeExecutor.exe" (
    echo.
    echo [SUCCESS] CodeExecutor.exe created successfully!
    echo Location: %CD%\CodeExecutor.exe
    echo Size: 
    for %%F in (CodeExecutor.exe) do echo   %%~zF bytes
    echo.
    echo Features:
    echo - Drag and drop code files
    echo - Automatic language detection
    echo - Support for: C, C++, Python, JavaScript, PowerShell, Batch
    echo - Compile and run in one click
    echo - Save output to file
    echo.
    echo You can now run: CodeExecutor.exe
    echo.
    pause
) else (
    echo [ERROR] Compilation failed
    echo.
    echo Check that you have .NET Framework 4.0+ installed
    pause
    exit /b 1
)
