@echo off
setlocal EnableDelayedExpansion
title Updating Executor

:: =====================================================
:: Paths and workspace
:: =====================================================
set "WORKDIR=%~dp0"
set "RUN_DIR=%WORKDIR%run_space"
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

rem === Move any backups to _debug directory on first run ===
set "DEBUG_DIR=%WORKDIR%_debug"
set "DEBUG_BACKUPS=%DEBUG_DIR%\backups"

if not exist "%DEBUG_DIR%" mkdir "%DEBUG_DIR%"

if exist "%WORKDIR%backups" (
    if not exist "%DEBUG_BACKUPS%" (
        mkdir "%DEBUG_BACKUPS%" 2>nul
        xcopy "%WORKDIR%backups\*" "%DEBUG_BACKUPS%\" /E /Y >nul 2>&1
        rmdir /s /q "%WORKDIR%backups" >nul 2>&1
    )
)

set "CLIP_TXT=%RUN_DIR%\clip_input.txt"
set "RUN_FILE=%RUN_DIR%\clip_run.bat"
set "CLIP_HELPER=%RUN_DIR%\read_clip.ps1"

echo [BOOT] Script starting...
echo.

:: =====================================================
:: Build PowerShell helper to read clipboard
::   (NO parentheses block; each line redirected directly)
:: =====================================================
> "%CLIP_HELPER%"  echo param([string]$OutPath)
>>"%CLIP_HELPER%" echo Add-Type -AssemblyName PresentationCore
>>"%CLIP_HELPER%" echo Add-Type -AssemblyName PresentationFramework
>>"%CLIP_HELPER%" echo try {
>>"%CLIP_HELPER%" echo     $text = [Windows.Clipboard]::GetText()
>>"%CLIP_HELPER%" echo     if (-not [string]::IsNullOrWhiteSpace($text)) {
>>"%CLIP_HELPER%" echo         Set-Content -Path $OutPath -Value $text -Encoding UTF8
>>"%CLIP_HELPER%" echo         exit 0
>>"%CLIP_HELPER%" echo     } else {
>>"%CLIP_HELPER%" echo         exit 1
>>"%CLIP_HELPER%" echo     }
>>"%CLIP_HELPER%" echo } catch {
>>"%CLIP_HELPER%" echo     exit 2
>>"%CLIP_HELPER%" echo }

if not exist "%CLIP_HELPER%" (
    echo [ERROR] Helper script was not created: "%CLIP_HELPER%"
    pause
    goto :eof
)

echo [DEBUG] Helper script written to "%CLIP_HELPER%"
echo.

:: =====================================================
:: Read clipboard into CLIP_TXT
:: =====================================================
del "%CLIP_TXT%" >nul 2>&1

echo [INFO] Reading clipboard text...
powershell -STA -NoProfile -ExecutionPolicy Bypass -File "%CLIP_HELPER%" "%CLIP_TXT%"
set "CLIPCODE=%ERRORLEVEL%"

if "%CLIPCODE%"=="0" (
    echo [INFO] Clipboard successfully read.
) else (
    echo [WARN] Clipboard read failed or was empty. (code %CLIPCODE%)
)

if exist "%CLIP_TXT%" (
    echo.
    echo ================== CLIPBOARD CONTENT ====================
    type "%CLIP_TXT%"
    echo ======================== END ============================
    echo.
) else (
    echo No clipboard content captured.
    >"%CLIP_TXT%" type nul
)

:: =====================================================
:: Ask user what to do
:: =====================================================
echo Choose an action:
echo [R] Run clipboard as script
echo [V] View only (do not run)
echo [E] Edit text before running
echo [Q] Quit
echo.

set "choice="
set /p "choice=Enter choice (R/V/E/Q): "
if /i "%choice%"=="Q" goto end

:: =====================================================
:: Convert text to temp .bat script in workspace
:: =====================================================
copy /y "%CLIP_TXT%" "%RUN_FILE%" >nul

if /i "%choice%"=="E" (
    start "" notepad "%RUN_FILE%"
    echo Edit and save, then close Notepad.
    pause
)
if /i "%choice%"=="V" (
    echo [INFO] Not executing. Script text at: "%RUN_FILE%"
    goto end
)

:: =====================================================
:: Run script in workspace directory
:: =====================================================
echo.
echo [INFO] Running clipboard script inside workspace "%RUN_DIR%"...
pushd "%RUN_DIR%"
call "%RUN_FILE%"
set "exitCode=%ERRORLEVEL%"
popd

echo ------------------------------------------------------
echo Script finished with exit code %exitCode%.
echo.

:end
echo [EXIT] Done.
endlocal
exit /b
