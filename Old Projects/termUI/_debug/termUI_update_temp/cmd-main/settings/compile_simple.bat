@echo off
REM Compile Settings Manager GUI (Simplified Version - No PowerShell SDK Required)

echo ===============================================
echo   Settings Manager - C# GUI Compiler
echo ===============================================
echo.

REM Find C# compiler
set CSC=
if exist "%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "CSC=%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
) else if exist "%windir%\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "CSC=%windir%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) else (
    echo [ERROR] C# compiler not found
    echo Please install .NET Framework 4.0 or higher
    echo.
    pause
    exit /b 1
)

echo [INFO] Using compiler: %CSC%
echo.

REM Set paths
set "SOURCE_FILE=%~dp0modules\csharp\SettingsManagerGUI_CS5.cs"
set "OUTPUT_FILE=%~dp0Settings-Manager.exe"

REM Check if source exists
if not exist "%SOURCE_FILE%" (
    echo [ERROR] Source file not found: %SOURCE_FILE%
    pause
    exit /b 1
)

REM Compile
echo [INFO] Compiling %SOURCE_FILE%...
echo.

"%CSC%" /target:winexe /out:"%OUTPUT_FILE%" /r:System.Windows.Forms.dll /r:System.Drawing.dll "%SOURCE_FILE%" 2>&1
set BUILD_ERR=%ERRORLEVEL%

if %BUILD_ERR% NEQ 0 goto :build_failed
goto :build_success

:build_success
echo.
echo ===============================================
echo   SUCCESS: Compilation Complete
echo ===============================================
echo.
echo Executable: %OUTPUT_FILE%
echo.
dir "%OUTPUT_FILE%" | findstr /r "[0-9]"
echo.
echo Running quick sanity check (auto-launching exe)...
if "%KEEP_GUI_OPEN%"=="1" goto :debug_mode
goto :keep_open_forever

:debug_mode
echo KEEP_GUI_OPEN=1 detected - launching GUI for debugging.
set "LOGFILE=%~dp0_debug\logs\important.log"
start "Settings-Manager-Debug" "%OUTPUT_FILE%"
set "START_TS=%date% %time%"
set "LAST_TS=%START_TS%"
if exist "%LOGFILE%" for %%A in ("%LOGFILE%") do set "LAST_TS=%%~tA"
REM Wait up to 10 seconds for log activity, else close
set /a _wait=0
:wait_loop
if %_wait% GEQ 10 goto :close_debug
timeout /t 1 /nobreak >nul
set /a _wait+=1
if exist "%LOGFILE%" for %%A in ("%LOGFILE%") do (
    if not "%%~tA"=="%LAST_TS%" goto :end_debug
)
goto :wait_loop

:close_debug
echo No log activity detected in 10s; closing debug session.
taskkill /im Settings-Manager.exe /f >nul 2>&1
goto :end_debug

:end_debug
echo Debug session finished. You can now run: Settings-Manager.exe
echo.
goto :end

:keep_open_forever
echo Launching GUI (non-debug) and leaving it open.
start "Settings-Manager" "%OUTPUT_FILE%"
echo GUI left running by design. Close manually when done.
echo You can now run: Settings-Manager.exe
echo.
goto :end

:build_failed
echo.
echo ===============================================
echo   ERROR: Compilation Failed
echo ===============================================
echo.
echo Error code: %BUILD_ERR%
echo Check the compiler output above for details
echo.

:end
pause
