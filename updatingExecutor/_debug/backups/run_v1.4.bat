@echo off
setlocal EnableDelayedExpansion
title Updating Executor

:: =====================================================
:: Paths / workspace - set early
:: =====================================================
set "WORKDIR=%~dp0"
set "RUN_DIR=%WORKDIR%run_space"

:: =====================================================
:: Check for wipe flag FIRST before any file operations
:: =====================================================
if /i "%1"=="/W" goto :WIPE_NEIGHBORS
if /i "%1"=="/WIPE" goto :WIPE_NEIGHBORS

:: =====================================================
:: Settings Management and Initialization
:: =====================================================
set "SETTINGS_FILE=%~dp0settings.ini"
set "LOG_DIR=%WORKDIR%run_space\log"

REM Default values
set "DEBUG=1"
set "TIMEOUT=0"
set "LOGLEVEL=2"
set "AUTOCLEAN=1"
set "HALTONERROR=0"
set "PERFMON=0"
set "RETRIES=3"
set "LANGUAGES=python,powershell,batch"
set "OUTPUT="
set "BACKUP=1"

REM Ensure settings.ini exists with default values
if not exist "%SETTINGS_FILE%" (
    echo [INFO] Creating default settings.ini...
    (
        echo # Updating Executor Settings
        echo # Format: KEY=VALUE ^(no spaces around =^)
        echo.
        echo # Enable or disable debug output
        echo DEBUG=1
        echo.
        echo # Timeout in seconds ^(0 = disabled, automatic termination after this duration^)
        echo TIMEOUT=0
        echo.
        echo # Log level ^(1=minimal, 2=normal, 3=verbose^)
        echo LOGLEVEL=2
        echo.
        echo # Auto-cleanup temp files on exit ^(0=disabled, 1=enabled^)
        echo AUTOCLEAN=1
        echo.
        echo # Halt on first error ^(0=continue, 1=stop^)
        echo HALTONERROR=0
        echo.
        echo # Performance monitoring ^(0=disabled, 1=enabled^)
        echo PERFMON=0
        echo.
        echo # Retry count for failed operations
        echo RETRIES=3
        echo.
        echo # Supported languages ^(comma-separated: python,powershell,batch,javascript,ruby,lua,shell^)
        echo LANGUAGES=python,powershell,batch
        echo.
        echo # Output directory for results ^(leave blank for run_space^)
        echo OUTPUT=
        echo.
        echo # Backup backups on wipe ^(0=disabled, 1=enabled^)
        echo BACKUP=1
        echo.
        echo # Version tracking
        echo VERSION=1.3
    ) > "%SETTINGS_FILE%"
)

REM Parse settings from ini file
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^DEBUG=" "%SETTINGS_FILE%" 2^>nul') do set "DEBUG=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^TIMEOUT=" "%SETTINGS_FILE%" 2^>nul') do set "TIMEOUT=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^LOGLEVEL=" "%SETTINGS_FILE%" 2^>nul') do set "LOGLEVEL=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^AUTOCLEAN=" "%SETTINGS_FILE%" 2^>nul') do set "AUTOCLEAN=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^HALTONERROR=" "%SETTINGS_FILE%" 2^>nul') do set "HALTONERROR=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^PERFMON=" "%SETTINGS_FILE%" 2^>nul') do set "PERFMON=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^RETRIES=" "%SETTINGS_FILE%" 2^>nul') do set "RETRIES=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^LANGUAGES=" "%SETTINGS_FILE%" 2^>nul') do set "LANGUAGES=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^OUTPUT=" "%SETTINGS_FILE%" 2^>nul') do set "OUTPUT=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^BACKUP=" "%SETTINGS_FILE%" 2^>nul') do set "BACKUP=%%b"

REM Trim whitespace from settings
set "DEBUG=%DEBUG: =%"
set "TIMEOUT=%TIMEOUT: =%"
set "LOGLEVEL=%LOGLEVEL: =%"
set "AUTOCLEAN=%AUTOCLEAN: =%"
set "HALTONERROR=%HALTONERROR: =%"
set "PERFMON=%PERFMON: =%"
set "RETRIES=%RETRIES: =%"
set "LANGUAGES=%LANGUAGES: =%"
set "OUTPUT=%OUTPUT: =%"
set "BACKUP=%BACKUP: =%"

if "%DEBUG%"=="1" (
    echo ========================================
    echo [DEBUG] Debug mode ENABLED
    echo [DEBUG] Timeout: %TIMEOUT% seconds
    echo [DEBUG] Log level: %LOGLEVEL%
    echo [DEBUG] Auto-clean: %AUTOCLEAN%
    echo [DEBUG] Halt on error: %HALTONERROR%
    echo [DEBUG] Performance monitor: %PERFMON%
    echo ========================================
    echo.
) else (
    echo [INFO] Normal mode - %TIMEOUT% second timeout active
    if "%TIMEOUT%"=="0" (
        start /min cmd /c "timeout /t 10 /nobreak >nul 2>&1 & taskkill /fi "WINDOWTITLE eq Updating Executor" /f >nul 2>&1"
    )
)

:BOOT_START

if "%DEBUG%"=="1" echo [DEBUG] Checking command-line arguments: %*
REM If argument is provided AND file doesn't exist, use argument
REM Otherwise, use existing file (pre-written by PowerShell wrapper)
if not "%*"=="" (
    if not exist "%RUN_DIR%\clip_input.txt" (
        if "%DEBUG%"=="1" echo [DEBUG] Writing args to clip_input.txt
        echo %* > "%RUN_DIR%\clip_input.txt"
        goto :SKIP_BOOT
    ) else (
        REM File exists, assume it was pre-written by PS wrapper
        if "%DEBUG%"=="1" echo [DEBUG] clip_input.txt exists, using pre-written file
        REM Just proceed with the file
        goto :SKIP_BOOT
    )
)

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

if /i "%boot_choice:~0,1%"=="W" goto :WIPE_NEIGHBORS
goto :SKIP_BOOT

:WIPE_NEIGHBORS
setlocal EnableDelayedExpansion
echo.
echo [INFO] Wiping workspace directory: %WORKDIR%
echo [INFO] Preserving: run.bat, backups/, run_space/

REM Initialize counters
set "DELETED_FILES=0"
set "DELETED_DIRS=0"

REM DEBUG MODE: List all files and directories before wiping
if "%DEBUG%"=="1" (
    echo.
    echo [DEBUG] Files to be deleted:
    cd /d "%WORKDIR%"
    for %%F in (*.*) do (
        if not "%%F"=="run.bat" (
            echo [DEBUG]   %%F
        )
    )
    echo.
    echo [DEBUG] Directories to be deleted:
    for /d %%D in (*) do (
        if not "%%D"=="backups" if not "%%D"=="run_space" (
            echo [DEBUG]   %%D
        )
    )
    echo.
)

REM Wipe run_space directory
if exist "%RUN_DIR%" (
    rmdir /s /q "%RUN_DIR%" >nul 2>&1
    echo [OK] run_space deleted.
    set "DELETED_DIRS=1"
)
mkdir "%RUN_DIR%"

REM Delete all files in WORKDIR except run.bat
cd /d "%WORKDIR%"
set "FILE_COUNT=0"
for %%F in (*.*) do (
    if not "%%F"=="run.bat" (
        del "%%F" >nul 2>&1
        set /a "FILE_COUNT+=1"
        if "%DEBUG%"=="1" echo [OK] %%F deleted.
    )
)
if !FILE_COUNT! gtr 0 (
    set /a "DELETED_FILES=!FILE_COUNT!"
)

REM Delete all subdirectories except backups and run_space
set "DIR_COUNT=0"
for /d %%D in (*) do (
    if not "%%D"=="backups" if not "%%D"=="run_space" (
        rmdir /s /q "%%D" >nul 2>&1
        set /a "DIR_COUNT+=1"
        if "%DEBUG%"=="1" echo [OK] %%D deleted.
    )
)
if !DIR_COUNT! gtr 0 (
    set /a "DELETED_DIRS=!DELETED_DIRS:0=0!+!DIR_COUNT!"
)

echo.
if !DELETED_FILES! equ 0 if !DELETED_DIRS! equ 1 (
    echo [INFO] Nothing to delete. Workspace is already clean.
) else (
    echo [INFO] Deleted: !DELETED_FILES! file^(s^), !DELETED_DIRS! director^(ies^)
)
echo [INFO] Workspace cleaned. Preserved: run.bat, backups/, run_space/
echo [INFO] Exiting.
endlocal
timeout /t 2 >nul
goto :END

:SKIP_BOOT
if "%DEBUG%"=="1" echo [DEBUG] Entered :SKIP_BOOT label
echo [INFO] Continuing normal operation...
echo.

:: =====================================================
:: Generate README on first run (instruction #7)
:: =====================================================
set "README_FILE=%RUN_DIR%\README.md"
if not exist "%README_FILE%" (
    echo [INFO] Generating README.md...
    (
        echo # Updating Executor - Code Executor Tool
        echo.
        echo ## Overview
        echo This is a clipboard-based code executor that automatically detects programming language,
        echo executes the code, and provides clear feedback on success or failure.
        echo.
        echo ## Supported Languages
        echo - Python ^(.py^)
        echo - PowerShell ^(.ps1^)
        echo - Batch ^(.bat^)
        echo - JavaScript ^(.js^)
        echo - Ruby ^(.rb^)
        echo - Lua ^(.lua^)
        echo - Shell ^(.sh^)
        echo.
        echo ## Features
        echo - Automatic language detection based on code patterns
        echo - Isolated execution environment in run_space/
        echo - Comprehensive logging in run_space/log/
        echo - Configurable behavior via settings.ini
        echo - Debug mode for troubleshooting
        echo - Automatic file cleanup on exit
        echo.
        echo ## Project Structure
        echo ```
        echo run.bat                    - Main executor ^(single-file, self-contained^)
        echo settings.ini               - Configuration file
        echo backups/                   - Version history
        echo run_space/                 - Isolated execution directory
        echo ├── log/                   - Log files
        echo │   ├── input.log          - User input history
        echo │   ├── important.log      - Critical events
        echo │   └── terminal.log       - Program output
        echo ├── languages/             - Code files organized by language
        echo ├── clip_input.txt         - Clipboard content
        echo └── README.md              - This file
        echo ```
        echo.
        echo ## Usage
        echo.
        echo ### Interactive Mode
        echo 1. Copy code to clipboard
        echo 2. Run: `.\run.bat`
        echo 3. Press [C] to continue or [W] to wipe workspace
        echo 4. Select action: [R] Run, [V] View, [E] Edit, or [Q] Quit
        echo.
        echo ### Command-Line Mode
        echo - `.\run.bat /W`       - Clean workspace
        echo - `.\run.bat /WIPE`    - Same as /W
        echo - `.\run.bat code`     - Execute code directly
        echo.
        echo ### Automated Testing
        echo When running tests, /W flag is recognized automatically to skip boot menu.
        echo.
        echo ## Configuration
        echo Edit `settings.ini` to customize:
        echo - DEBUG: Enable debug output ^(0/1^)
        echo - TIMEOUT: Execution timeout in seconds ^(0=disabled^)
        echo - LOGLEVEL: Verbosity ^(1=minimal, 2=normal, 3=verbose^)
        echo - AUTOCLEAN: Auto-cleanup temp files ^(0/1^)
        echo - HALTONERROR: Stop on first error ^(0/1^)
        echo - PERFMON: Performance monitoring ^(0/1^)
        echo - RETRIES: Retry count for failed operations
        echo - LANGUAGES: Supported language list
        echo.
        echo ## Logging
        echo - **input.log**: All user inputs ^(interactive mode^)
        echo - **important.log**: Critical events, errors, execution results
        echo - **terminal.log**: Full program output ^(if enabled^)
        echo.
        echo ## Exit Codes
        echo - 0: Success
        echo - 1: Failure
        echo - 2: Missing dependency
        echo.
        echo ## Troubleshooting
        echo.
        echo ### Code not executing?
        echo 1. Verify code is in clipboard: Ctrl+C to copy
        echo 2. Check language detection: Enable DEBUG=1 in settings.ini
        echo 3. Review logs in run_space/log/
        echo.
        echo ### Syntax errors in code?
        echo 1. Run with [V] View to see exact code being executed
        echo 2. Fix code and copy again to clipboard
        echo 3. Re-run executor
        echo.
        echo ### Workspace cleanup?
        echo 1. Press [W] at boot menu to wipe all files except run.bat
        echo 2. Or run: `.\run.bat /W`
        echo.
        echo ## Version
        echo %VERSION:1.0=1.3%
        echo.
        echo Generated automatically on first run.
    ) > "%README_FILE%"
)

:: Clean up any old temp files
del "%RUN_DIR%\*.tmp" >nul 2>&1

set "CLIP_TXT=%RUN_DIR%\clip_input.txt"
set "CLIP_HELPER=%RUN_DIR%\read_clipboard.ps1"
set "BOM_STRIPPER=%RUN_DIR%\strip_bom.bat"
set "CODE_EXECUTOR=%RUN_DIR%\execute_code.bat"

if "%DEBUG%"=="1" (
    echo [DEBUG] Variables set:
    echo [DEBUG]   CLIP_TXT=%CLIP_TXT%
    echo [DEBUG]   CODE_EXECUTOR=%CODE_EXECUTOR%
)

:: =====================================================
:: Ensure helper scripts exist in run_space
:: =====================================================
if not exist "%CLIP_HELPER%" (
    if "%DEBUG%"=="1" echo [DEBUG] Generating read_clipboard.ps1...
    (
        echo param^([string]$OutputFile^)
        echo try {
        echo     $txt = Get-Clipboard -Raw
        echo     $txt = $txt.TrimStart^([char]0xFEFF^)
        echo     if ^([string]::IsNullOrWhiteSpace^($txt^)^) {
        echo         "" ^| Set-Content -Path $OutputFile -Encoding ASCII
        echo         exit 1
        echo     }
        echo     $txt ^| Set-Content -Path $OutputFile -Encoding ASCII
        echo     exit 0
        echo } catch {
        echo     "" ^| Set-Content -Path $OutputFile -Encoding ASCII
        echo     exit 2
        echo }
    ) > "%CLIP_HELPER%"
)

if not exist "%BOM_STRIPPER%" (
    if "%DEBUG%"=="1" echo [DEBUG] Generating strip_bom.bat...
    (
        echo @echo off
        echo setlocal
        echo set "INPUT=%%~1"
        echo set "OUTPUT=%%~2"
        echo if not defined INPUT exit /b 1
        echo if not defined OUTPUT exit /b 1
        echo if not exist "%%INPUT%%" exit /b 1
        echo more "%%INPUT%%" ^> "%%OUTPUT%%.tmp"
        echo if errorlevel 1 exit /b 1
        echo move /y "%%OUTPUT%%.tmp" "%%OUTPUT%%" ^>nul
        echo exit /b 0
    ) > "%BOM_STRIPPER%"
)

if not exist "%CODE_EXECUTOR%" (
    if "%DEBUG%"=="1" echo [DEBUG] Generating execute_code.bat...
    (
        echo @echo off
        echo setlocal enabledelayedexpansion
        echo set "FILE=%%~1"
        echo if not defined FILE ^(echo [ERROR] No file specified ^& exit /b 1^)
        echo if not exist "%%FILE%%" ^(echo [ERROR] File not found: %%FILE%% ^& exit /b 1^)
        echo set "EXT=%%~x1"
        echo.
        echo REM Batch/CMD
        echo if /i "%%EXT%%"==".bat" ^(echo [RUN] Batch script detected ^& call "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo if /i "%%EXT%%"==".cmd" ^(echo [RUN] CMD script detected ^& call "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM PowerShell
        echo if /i "%%EXT%%"==".ps1" ^(echo [RUN] PowerShell script detected ^& powershell -NoProfile -ExecutionPolicy Bypass -File "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM Python
        echo if /i "%%EXT%%"==".py" ^(echo [RUN] Python script detected ^& python "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM JavaScript
        echo if /i "%%EXT%%"==".js" ^(echo [RUN] JavaScript detected ^& node "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM Lua
        echo if /i "%%EXT%%"==".lua" ^(echo [RUN] Lua script detected ^& lua "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM Ruby
        echo if /i "%%EXT%%"==".rb" ^(echo [RUN] Ruby script detected ^& ruby "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM Shell
        echo if /i "%%EXT%%"==".sh" ^(echo [RUN] Shell script detected ^& bash "%%FILE%%" ^& exit /b ^^!ERRORLEVEL^^!^)
        echo.
        echo REM C - simplified without compilation
        echo if /i "%%EXT%%"==".c" ^(echo [ERROR] C compilation not supported in generated executor ^& exit /b 1^)
        echo if /i "%%EXT%%"==".cpp" ^(echo [ERROR] C++ compilation not supported in generated executor ^& exit /b 1^)
        echo.
        echo echo [ERROR] Unknown file type: %%EXT%%
        echo echo Supported: .bat, .cmd, .ps1, .py, .js, .lua, .rb, .sh
        echo exit /b 1
    ) > "%CODE_EXECUTOR%"
)

:: =====================================================
:: Read clipboard into CLIP_TXT (skip if already set from args)
:: =====================================================
if not exist "%CLIP_TXT%" (
    del "%CLIP_TXT%"  >nul 2>&1

    echo [INFO] Reading clipboard text...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CLIP_HELPER%" "%CLIP_TXT%"
    set "CLIPCODE=!ERRORLEVEL!"

    if "!CLIPCODE!"=="0" (
        echo [INFO] Clipboard successfully read.
    ) else if "!CLIPCODE!"=="1" (
        echo [WARN] Clipboard was empty.
    ) else (
        echo [WARN] Clipboard read exception (code !CLIPCODE!)
    )

    if not exist "%CLIP_TXT%" (
        >"%CLIP_TXT%" type nul
    )

    :: Extra safety: strip any BOMs
    if exist "%BOM_STRIPPER%" (
        call "%BOM_STRIPPER%" "%CLIP_TXT%" "%CLIP_TXT%" >nul 2>&1
    )
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
:: Auto-run if called with argument
:: =====================================================
if not "%*"=="" (
    echo [INFO] Auto-running from command-line argument...
    if "%DEBUG%"=="1" echo [DEBUG] Setting choice=R and jumping to :DETECT_AND_RUN
    set "choice=R"
    goto :DETECT_AND_RUN
)

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
:DETECT_AND_RUN
if "%DEBUG%"=="1" echo [DEBUG] Entered :DETECT_AND_RUN - choice=%choice%

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
:: Detect and set file extension
:: =====================================================
if "%DEBUG%"=="1" echo [DEBUG] Starting language detection...
setlocal enabledelayedexpansion
set "detected_ext=.txt"
set "CLIP_FILE=%CLIP_TXT%"

if "%DEBUG%"=="1" echo [DEBUG] Checking Python patterns...
REM Check for Python - look for print keyword first
findstr /i "print" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

findstr /i "python" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

findstr /i "import " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

findstr /i "def " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

findstr /i "class " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

findstr /i "if __name__" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.py" & goto :DETECT_DONE)

if "%DEBUG%"=="1" echo [DEBUG] After Python checks, before PowerShell
if "%DEBUG%"=="1" echo [DEBUG] No Python match, checking PowerShell...
REM Check for PowerShell - multiple patterns
findstr /i "Write-Host" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.ps1" & goto :DETECT_DONE)

findstr /i "Write-Output" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.ps1" & goto :DETECT_DONE)

findstr /i "Get-" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.ps1" & goto :DETECT_DONE)

findstr /i "Set-" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.ps1" & goto :DETECT_DONE)

findstr /i "param" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.ps1" & goto :DETECT_DONE)

REM Check for C/C++ - look for includes and main function
findstr /i "#include" "%CLIP_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i "iostream" "%CLIP_FILE%" >nul 2>&1
    if %errorlevel% equ 0 (
        set "detected_ext=.cpp" & goto :DETECT_DONE
    ) else (
        set "detected_ext=.c" & goto :DETECT_DONE
    )
)

findstr /i "int main" "%CLIP_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i "std::" "%CLIP_FILE%" >nul 2>&1
    if %errorlevel% equ 0 (
        set "detected_ext=.cpp" & goto :DETECT_DONE
    ) else (
        set "detected_ext=.c" & goto :DETECT_DONE
    )
)

REM Check for JavaScript
findstr "console.log" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.js" & goto :DETECT_DONE)

findstr /i "const " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.js" & goto :DETECT_DONE)

findstr /i "let " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.js" & goto :DETECT_DONE)

findstr /i "function " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.js" & goto :DETECT_DONE)

REM Check for Ruby
findstr /i "puts " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.rb" & goto :DETECT_DONE)

findstr /i "require " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.rb" & goto :DETECT_DONE)

REM Check for Lua
findstr /i "local " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.lua" & goto :DETECT_DONE)

REM Check for batch/cmd - prioritize specific batch patterns
findstr /i "@echo off" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.bat" & goto :DETECT_DONE)

findstr /i "setlocal" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.bat" & goto :DETECT_DONE)

findstr /i "set " "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.bat" & goto :DETECT_DONE)

REM Check for Shell (bash/sh) before generic echo
findstr /i "#!/bin/bash" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.sh" & goto :DETECT_DONE)

findstr /i "#!/bin/sh" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.sh" & goto :DETECT_DONE)

REM Generic echo as last resort - default to batch
findstr /i "echo" "%CLIP_FILE%" >nul 2>&1 && (set "detected_ext=.bat" & goto :DETECT_DONE)

:DETECT_DONE
if "%DEBUG%"=="1" echo [DEBUG] Detected extension: !detected_ext!

REM If still .txt, warn user but continue - execute_code.bat will handle error
if "!detected_ext!"==".txt" (
    echo [WARN] Could not detect language type.
    echo [WARN] Defaulting to .txt - execution will likely fail.
    echo [WARN] Add language-specific keywords for auto-detection.
)

set "RUN_FILE=%RUN_DIR%\clipboard_code!detected_ext!"
if "%DEBUG%"=="1" echo [DEBUG] RUN_FILE will be: !RUN_FILE!
endlocal & set "RUN_FILE=%RUN_FILE%"

copy /y "%CLIP_TXT%" "%RUN_FILE%" >nul
if "%DEBUG%"=="1" echo [DEBUG] Copied %CLIP_TXT% to %RUN_FILE%
if "%DEBUG%"=="1" echo [DEBUG] Checking choice handlers - choice=%choice%

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
if "%DEBUG%"=="1" echo [DEBUG] About to execute code
echo.
echo [INFO] Running code from clipboard in workspace "%RUN_DIR%"...
echo [INFO] File: %RUN_FILE%
if "%DEBUG%"=="1" echo [DEBUG] Pushing to directory: %RUN_DIR%
pushd "%RUN_DIR%"

REM Ensure executor exists
if not exist "%CODE_EXECUTOR%" (
    echo [ERROR] Code executor not found at %CODE_EXECUTOR%
    popd
    goto END
)

if "%DEBUG%"=="1" echo [DEBUG] Calling: %CODE_EXECUTOR% "%RUN_FILE%"
call "%CODE_EXECUTOR%" "%RUN_FILE%"
set "exitCode=!ERRORLEVEL!"
if "%DEBUG%"=="1" echo [DEBUG] Execution completed with exit code: !exitCode!
popd

echo.
echo ======================================================
echo Script finished with exit code !exitCode!.
echo ======================================================
echo.

:RESTART_PROMPT
if not "%*"=="" (
    REM Auto-run mode - exit immediately
    echo [INFO] Auto-run complete. Exiting...
) else (
    REM Interactive mode - ask to restart
    set /p "restart=Run another code? (Y/N): "
    if /i "!restart:~0,1!"=="Y" (
        del "%RUN_DIR%\clip_input.txt" >nul 2>&1
        goto :BOOT_START
    )
)

:END
:: Final cleanup of temp .tmp files
del "%RUN_DIR%\*.tmp" >nul 2>&1
del "%RUN_DIR%\.autorun" >nul 2>&1

echo [EXIT] Done.
endlocal
exit /b
