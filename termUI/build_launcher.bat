@echo off
setlocal

echo [INFO] Building enhanced termUI.exe launcher...
echo.

rem Try .NET Framework csc.exe first (faster, more compatible)
set "CSC_PATH="
for /f "tokens=*" %%A in ('where csc.exe 2^>nul') do (
    set "CSC_PATH=%%A"
    goto :found_csc
)

rem Try default .NET Framework paths
if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    goto :found_csc
)

if exist "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    goto :found_csc
)

echo [ERROR] C# compiler (csc.exe) not found
exit /b 1

:found_csc
echo [INFO] Found C# compiler: %CSC_PATH%

rem Backup existing exe if present
if exist termUI.exe (
    echo [INFO] Backing up existing termUI.exe...
    move /Y termUI.exe termUI.exe.backup >nul 2>&1
)

rem Compile with System.Net reference for WebClient
"%CSC_PATH%" /out:termUI.exe /reference:System.Net.dll /reference:System.IO.Compression.FileSystem.dll TermUILauncher.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] termUI.exe created successfully
    if exist termUI.exe.backup (
        del termUI.exe.backup >nul 2>&1
    )
    rem Keep TermUILauncher.cs for future edits (no cleanup)
    dir termUI.exe
    exit /b 0
) else (
    echo.
    echo [ERROR] Compilation failed with exit code %ERRORLEVEL%
    if exist termUI.exe.backup (
        echo [INFO] Restoring backup...
        move /Y termUI.exe.backup termUI.exe >nul 2>&1
    )
    exit /b 1
)
