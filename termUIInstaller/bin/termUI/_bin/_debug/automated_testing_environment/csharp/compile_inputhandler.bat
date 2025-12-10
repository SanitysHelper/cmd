@echo off
setlocal
set SRC=%~dp0InputHandler.cs
set OUT=%~dp0bin\InputHandler.exe
if not exist "%~dp0bin" mkdir "%~dp0bin" >nul 2>&1

REM Try to find csc.exe in .NET Framework directories
set CSC=
for /f "delims=" %%i in ('dir /s /b "C:\Windows\Microsoft.NET\Framework64\v*\csc.exe" 2^>nul') do set CSC=%%i & goto :found
for /f "delims=" %%i in ('dir /s /b "C:\Windows\Microsoft.NET\Framework\v*\csc.exe" 2^>nul') do set CSC=%%i & goto :found
:found

if not defined CSC (
    echo [ERROR] csc.exe not found. Install .NET SDK or Visual Studio.
    exit /b 1
)

echo [INFO] Using: %CSC%
"%CSC%" /nologo /t:exe /out:"%OUT%" "%SRC%"
if errorlevel 1 (
    echo [ERROR] Compile failed
    exit /b 1
)
echo [INFO] Built %OUT%
