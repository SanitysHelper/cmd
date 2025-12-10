@echo off
REM termUI Installer - Compilation Script
REM Compiles termUIInstaller.cpp to executable

setlocal enabledelayedexpansion

echo =============================================
echo   Compiling termUI Installer
echo =============================================
echo.

REM Check if Visual Studio compiler is available
where cl.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using MSVC compiler
    goto :COMPILE_MSVC
)

REM Check if MinGW g++ is available
where g++.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using MinGW g++ compiler
    goto :COMPILE_MINGW
)

echo [ERROR] No C++ compiler found!
echo.
echo Please install one of the following:
echo   1. Visual Studio (with C++ Build Tools)
echo   2. MinGW-w64
echo.
echo If you have Visual Studio installed, run this script from:
echo   "Developer Command Prompt for VS"
echo.
pause
exit /b 1

:COMPILE_MSVC
echo Compiling with MSVC...
cl.exe /EHsc /O2 /Fe:bin\termUIInstaller.exe termUIInstaller.cpp wininet.lib shell32.lib

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Compilation complete!
    echo Executable: bin\termUIInstaller.exe
    echo.
    
    REM Clean up intermediate files
    del *.obj 2>nul
    
    exit /b 0
) else (
    echo.
    echo [ERROR] Compilation failed!
    echo.
    pause
    exit /b 1
)

:COMPILE_MINGW
echo Compiling with MinGW g++...
g++ -std=c++11 -O2 -o bin\termUIInstaller.exe termUIInstaller.cpp -lwininet -lole32 -static-libgcc -static-libstdc++

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Compilation complete!
    echo Executable: bin\termUIInstaller.exe
    echo.
    exit /b 0
) else (
    echo.
    echo [ERROR] Compilation failed!
    echo.
    pause
    exit /b 1
)
