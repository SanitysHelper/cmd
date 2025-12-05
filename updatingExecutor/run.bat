@echo off
setlocal EnableDelayedExpansion
title Updating Executor

:: =====================================================
:: Paths / workspace
:: =====================================================
set "WORKDIR=%~dp0"
set "RUN_DIR=%WORKDIR%run_space"
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

:: Clean up any old temp files
del "%RUN_DIR%\*.tmp" >nul 2>&1

set "TMP_CLIP=%RUN_DIR%\clipread.tmp"
set "CLIP_TXT=%RUN_DIR%\clip_input.txt"
set "RUN_FILE=%RUN_DIR%\clip_run.bat"
set "CLIP_HELPER=%RUN_DIR%\read_clip.ps1"

echo [BOOT] Script starting...
echo.

:: =====================================================
:: Build PowerShell helper that writes clipboard to TMP
::   - Strips BOM (0xFEFF)
::   - Writes ASCII to avoid adding a BOM
:: =====================================================
> "%CLIP_HELPER%"  echo param([string]$TmpPath)
>>"%CLIP_HELPER%" echo try {
>>"%CLIP_HELPER%" echo   $txt = Get-Clipboard -Raw
>>"%CLIP_HELPER%" echo   $txt = $txt.TrimStart([char]0xFEFF)
>>"%CLIP_HELPER%" echo   if ([string]::IsNullOrWhiteSpace($txt)) {
>>"%CLIP_HELPER%" echo     "" ^| Set-Content -Path $TmpPath -Encoding ASCII
>>"%CLIP_HELPER%" echo     exit 1
>>"%CLIP_HELPER%" echo   } else {
>>"%CLIP_HELPER%" echo     $txt ^| Set-Content -Path $TmpPath -Encoding ASCII
>>"%CLIP_HELPER%" echo     exit 0
>>"%CLIP_HELPER%" echo   }
>>"%CLIP_HELPER%" echo } catch {
>>"%CLIP_HELPER%" echo   "" ^| Set-Content -Path $TmpPath -Encoding ASCII
>>"%CLIP_HELPER%" echo   exit 2
>>"%CLIP_HELPER%" echo }

if not exist "%CLIP_HELPER%" (
    echo [ERROR] Failed to create helper script: "%CLIP_HELPER%"
    pause
    goto :END
)

:: =====================================================
:: Read clipboard into TMP_CLIP
:: =====================================================
del "%TMP_CLIP%"  >nul 2>&1
del "%CLIP_TXT%"  >nul 2>&1

echo [INFO] Reading clipboard text...
powershell -NoProfile -ExecutionPolicy Bypass -File "%CLIP_HELPER%" "%TMP_CLIP%"
set "CLIPCODE=%ERRORLEVEL%"

if "%CLIPCODE%"=="0" (
    echo [INFO] Clipboard successfully read.
) else (
    echo [WARN] Clipboard read failed or was empty. (code %CLIPCODE%)
)

if exist "%TMP_CLIP%" (
    copy /y "%TMP_CLIP%" "%CLIP_TXT%" >nul
) else (
    >"%CLIP_TXT%" type nul
)

:: Extra safety: re-write via MORE (drops BOMs if any slipped through)
if exist "%CLIP_TXT%" (
    more "%CLIP_TXT%" > "%CLIP_TXT%.tmp"
    move /y "%CLIP_TXT%.tmp" "%CLIP_TXT%" >nul
)

:: =====================================================
:: Show clipboard content
:: =====================================================
echo.
echo ================== CLIPBOARD CONTENT ====================
type "%CLIP_TXT%"
echo ======================== END ============================
echo.

:: =====================================================
:: Ask what to do
:: =====================================================
echo Choose an action:
echo [R] Run clipboard as script
echo [V] View only (do not run)
echo [E] Edit text before running
echo [Q] Quit
echo.

set "choice="
set /p "choice=Enter choice (R/V/E/Q): "
if /i "%choice%"=="Q" goto END

:: =====================================================
:: Convert text to .bat script in workspace
:: =====================================================
copy /y "%CLIP_TXT%" "%RUN_FILE%" >nul

if /i "%choice%"=="E" (
    start "" notepad "%RUN_FILE%"
    echo Edit and save the file, then close Notepad.
    pause
)

if /i "%choice%"=="V" (
    echo [INFO] Not executing. Script saved as:
    echo   "%RUN_FILE%"
    goto END
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

:END
:: Final cleanup of temp .tmp files
del "%RUN_DIR%\*.tmp" >nul 2>&1

echo [EXIT] Done.
endlocal
exit /b
