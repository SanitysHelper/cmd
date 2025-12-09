@echo off
REM Compile Settings Manager C# GUI to executable

echo Compiling Settings Manager GUI...

REM Find C# compiler (multiple locations)
set CSC=
if exist "%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "CSC=%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
) else if exist "%windir%\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "CSC=%windir%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) else (
    echo [ERROR] C# compiler not found. Install .NET Framework 4.0 or higher
    exit /b 1
)

echo Using compiler: %CSC%

REM Set paths
set "SOURCE_FILE=%~dp0modules\csharp\SettingsManagerGUI.cs"
set "OUTPUT_FILE=%~dp0Settings-Manager.exe"
set "ICON_FILE=%~dp0modules\csharp\icon.ico"

REM Check if source exists
if not exist "%SOURCE_FILE%" (
    echo [ERROR] Source file not found: %SOURCE_FILE%
    exit /b 1
)

REM Compile
echo Compiling %SOURCE_FILE%...

if exist "%ICON_FILE%" (
    "%CSC%" /target:winexe /out:"%OUTPUT_FILE%" /r:System.Management.Automation.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:Microsoft.VisualBasic.dll /win32icon:"%ICON_FILE%" "%SOURCE_FILE%"
) else (
    "%CSC%" /target:winexe /out:"%OUTPUT_FILE%" /r:System.Management.Automation.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:Microsoft.VisualBasic.dll "%SOURCE_FILE%"
)

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Compiled successfully: %OUTPUT_FILE%
    echo File size: 
    dir /b "%OUTPUT_FILE%" | findstr /r "^"
    echo.
    echo You can now run Settings-Manager.exe
) else (
    echo [ERROR] Compilation failed with error code %ERRORLEVEL%
    exit /b 1
)

pause
