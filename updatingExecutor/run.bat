@echo off
setlocal EnableDelayedExpansion
title Updating Executor

:: =====================================================
:: Paths / workspace
:: =====================================================
set "WORKDIR=%~dp0"
set "RUN_DIR=%WORKDIR%run_space"
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

echo [BOOT] Script starting...
echo.

:: =====================================================
:: Wipe runspace option
:: =====================================================
echo Choose an action:
echo [C] Continue normally (default)
echo [W] Wipe entire run_space directory and exit
echo.

set "boot_choice="
set /p "boot_choice=Enter choice (C/W): "

REM Normalize input to uppercase
if "%boot_choice%"=="" set "boot_choice=C"

if /i "%boot_choice:~0,1%"=="W" (
    echo.
    echo [INFO] Wiping run_space directory: %RUN_DIR%
    rmdir /s /q "%RUN_DIR%" >nul 2>&1
    mkdir "%RUN_DIR%"
    echo [OK] run_space wiped clean.
    echo.
    echo [INFO] All files deleted. Exiting.
    timeout /t 2 >nul
    goto :END
)

echo [INFO] Continuing normal operation...
echo.

:: Clean up any old temp files
del "%RUN_DIR%\*.tmp" >nul 2>&1

set "CLIP_TXT=%RUN_DIR%\clip_input.txt"
set "CLIP_HELPER=%RUN_DIR%\read_clipboard.ps1"
set "BOM_STRIPPER=%RUN_DIR%\strip_bom.bat"

:: =====================================================
:: Ensure helper scripts exist in run_space
:: =====================================================
if not exist "%CLIP_HELPER%" (
    echo [INFO] Restoring clipboard helper...
    copy /y "%WORKDIR%read_clipboard.ps1" "%CLIP_HELPER%" >nul 2>&1
)

if not exist "%BOM_STRIPPER%" (
    echo [INFO] Restoring BOM stripper...
    copy /y "%WORKDIR%strip_bom.bat" "%BOM_STRIPPER%" >nul 2>&1
)

:: =====================================================
:: Read clipboard into CLIP_TXT
:: =====================================================
del "%CLIP_TXT%"  >nul 2>&1

echo [INFO] Reading clipboard text...
powershell -NoProfile -ExecutionPolicy Bypass -File "%CLIP_HELPER%" "%CLIP_TXT%"
set "CLIPCODE=%ERRORLEVEL%"

if "%CLIPCODE%"=="0" (
    echo [INFO] Clipboard successfully read.
) else if "%CLIPCODE%"=="1" (
    echo [WARN] Clipboard was empty.
) else (
    echo [WARN] Clipboard read exception (code %CLIPCODE%)
)

if not exist "%CLIP_TXT%" (
    >"%CLIP_TXT%" type nul
)

:: Extra safety: strip any BOMs
if exist "%BOM_STRIPPER%" (
    call "%BOM_STRIPPER%" "%CLIP_TXT%" "%CLIP_TXT%" >nul 2>&1
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
:MENU
echo Choose an action:
echo [R] Run clipboard as script (auto-detects language)
echo [V] View only (do not run)
echo [E] Edit text before running
echo [D] Detect file type
echo [Q] Quit
echo.

set "choice="
set /p "choice=Enter choice (R/V/E/D/Q): "
if /i "%choice%"=="Q" goto END

:: =====================================================
:: Detect file type from clipboard content
:: =====================================================
if /i "%choice%"=="D" (
    echo.
    echo Analyzing clipboard content...
    setlocal enabledelayedexpansion
    set /p "first_line=" < "%CLIP_TXT%"
    
    if "!first_line!"=="" (
        echo [INFO] File appears to be empty
    ) else (
        echo First line: !first_line!
        if "!first_line:~0,1!"=="@" (
            echo [DETECT] Batch/CMD script detected
        ) else if "!first_line:~0,1!"==":" (
            echo [DETECT] Batch/CMD script detected  
        ) else if "!first_line:~0,1!"=="^#" (
            if "!first_line:~2,3!"=="python" (
                echo [DETECT] Python script detected
            ) else if "!first_line:~2,5!"=="bash" (
                echo [DETECT] Bash script detected
            ) else (
                echo [DETECT] Shell script detected
            )
        ) else if "!first_line:~0,2!"=="-*-" (
            echo [DETECT] Could be various script types
        ) else (
            echo [DETECT] Unknown type - will attempt execution
        )
    )
    endlocal
    echo.
    goto :MENU
)

:: =====================================================
:: Save clipboard content to appropriately named file
:: =====================================================
echo.

REM Try to detect extension from first line shebang or content
setlocal enabledelayedexpansion
set "detected_ext=.txt"

REM Check for Python shebang
findstr /r "^#!.*python" "%CLIP_TXT%" >nul
if !errorlevel! equ 0 (
    set "detected_ext=.py"
) else (
    REM Check for bash/shell shebang
    findstr /r "^#!.*bash" "%CLIP_TXT%" >nul
    if !errorlevel! equ 0 (
        set "detected_ext=.sh"
    ) else (
        REM Check for batch/cmd patterns
        findstr /i "^@echo off" "%CLIP_TXT%" >nul
        if !errorlevel! equ 0 (
            set "detected_ext=.bat"
        )
    )
)

set "RUN_FILE=%RUN_DIR%\clipboard_code!detected_ext!"
endlocal

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
:: Run script using universal executor
:: =====================================================
echo.
echo [INFO] Running code from clipboard in workspace "%RUN_DIR%"...
echo [INFO] File: %RUN_FILE%
pushd "%RUN_DIR%"

REM Ensure executor exists
if not exist "execute_code.bat" (
    echo [ERROR] Code executor not found
    popd
    goto END
)

call execute_code.bat "%RUN_FILE%"
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
