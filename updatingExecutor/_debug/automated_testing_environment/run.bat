@echo off
setlocal EnableDelayedExpansion
title Updating Executor

:: =====================================================
:: Paths / workspace - set early
:: =====================================================
set "WORKDIR=%~dp0"
set "RUN_DIR=%WORKDIR%run_space"

:: =====================================================
:: Interrupt handler setup (batch has limited Ctrl+C support)
:: We use a cleanup trap that's called before exit
:: =====================================================
REM Register cleanup on exit using cmd /c wrapper
REM This ensures temp files are cleaned regardless of termination

:: =====================================================
:: Check for wipe flag FIRST before any file operations
:: =====================================================
if /i "%1"=="/W" goto :WIPE_NEIGHBORS
if /i "%1"=="/WIPE" goto :WIPE_NEIGHBORS

:: =====================================================
:: Move backups to _debug directory (runs once)
:: =====================================================
set "DEBUG_DIR=%WORKDIR%_debug"
set "DEBUG_BACKUPS=%DEBUG_DIR%\backups"
set "TEST_ENV=%DEBUG_DIR%\_testenv"

REM Create _debug directory structure if it doesn't exist
if not exist "%DEBUG_DIR%" mkdir "%DEBUG_DIR%"
if not exist "%DEBUG_BACKUPS%" mkdir "%DEBUG_BACKUPS%"

REM Move backups to _debug if original backups folder exists
if exist "%WORKDIR%backups" (
    if not exist "%DEBUG_BACKUPS%\run_v1.0.bat" (
        echo [INFO] Moving backups to _debug directory...
        REM Copy all files from backups to _debug\backups
        xcopy "%WORKDIR%backups\*" "%DEBUG_BACKUPS%\" /E /Y >nul 2>&1
        REM Delete original backups folder
        rmdir /s /q "%WORKDIR%backups" >nul 2>&1
        echo [OK] Backups moved to _debug\backups and original deleted.
    )
)

:: =====================================================
:: Settings Management and Initialization
:: =====================================================
set "SETTINGS_FILE=%~dp0settings.ini"

REM Set log directory to _debug/logs
set "LOG_DIR=%DEBUG_DIR%\logs"

REM Create log directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Set up helper scripts locations
set "MENU_HELPER=%RUN_DIR%\arrow_menu.ps1"
set "CLIP_HELPER=%RUN_DIR%\read_clipboard.ps1"
set "BOM_STRIPPER=%RUN_DIR%\strip_bom.bat"
set "CODE_EXECUTOR=%RUN_DIR%\execute_code.bat"

REM Create run_space directory if it doesn't exist
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

REM Log file paths with program name prefix
set "LOG_IMPORTANT=%LOG_DIR%\updatingExecutor_important.log"
set "LOG_INPUT=%LOG_DIR%\updatingExecutor_input.log"
set "LOG_TERMINAL=%LOG_DIR%\updatingExecutor_terminal.log"

REM Initialize log timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set "logdate=%%c-%%a-%%b")
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set "logtime=%%a:%%b")

REM Helper macro for logging to important.log
REM Usage: call :LOGIMPORTANT "message"
REM (defined later in script)

REM Default values
set "DEBUG=0"
set "TIMEOUT=0"
set "LOGLEVEL=2"
set "AUTOCLEAN=1"
set "HALTONERROR=0"
set "PERFMON=0"
set "RETRIES=3"
set "LANGUAGES=python,powershell,batch"
set "OUTPUT="
set "BACKUP=1"
set "AUTOINPUT=1"
set "WAITTIME=5"
set "ENABLEWIPE=1"
set "ENABLEPREVIOUSCODE=1"

REM Ensure settings.ini exists with default values
if not exist "%SETTINGS_FILE%" (
    echo [INFO] Creating default settings.ini...
    (
        echo # Updating Executor Settings
        echo # Format: KEY=VALUE ^(no spaces around =^)
        echo.
        echo # Enable or disable debug output ^(0=off, 1=on^)
        echo DEBUG=0
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
        echo # Enable automatic input waiting feature ^(0=disabled, 1=enabled^) - when disabled, user has unlimited time to choose
        echo AUTOINPUT=1
        echo.
        echo # Wait time in seconds for timeouts ^(used for boot menu and input prompts^)
        echo WAITTIME=5
        echo.
        echo # Enable wipe option at boot menu ^(0=disabled, 1=enabled^)
        echo ENABLEWIPE=1
        echo.
        echo # Enable previous code execution feature ^(0=disabled, 1=enabled^)
        echo ENABLEPREVIOUSCODE=1
        echo.
        echo # Version tracking
        echo VERSION=1.4
    ) > "%SETTINGS_FILE%"
    echo [INFO] Settings file created. Please configure your preferences.
    echo.
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
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^AUTOINPUT=" "%SETTINGS_FILE%" 2^>nul') do set "AUTOINPUT=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^WAITTIME=" "%SETTINGS_FILE%" 2^>nul') do set "WAITTIME=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^ENABLEWIPE=" "%SETTINGS_FILE%" 2^>nul') do set "ENABLEWIPE=%%b"
for /f "tokens=1,2 delims==" %%a in ('findstr /i "^ENABLEPREVIOUSCODE=" "%SETTINGS_FILE%" 2^>nul') do set "ENABLEPREVIOUSCODE=%%b"

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
set "AUTOINPUT=%AUTOINPUT: =%"
set "WAITTIME=%WAITTIME: =%"
set "ENABLEWIPE=%ENABLEWIPE: =%"
set "ENABLEPREVIOUSCODE=%ENABLEPREVIOUSCODE: =%"

REM Normalize AUTOINPUT and WAITTIME values
set "AUTOINPUT=%AUTOINPUT:~0,1%"
if /i not "%AUTOINPUT%"=="0" if /i not "%AUTOINPUT%"=="1" set "AUTOINPUT=1"
for /f "delims=" %%W in ("%WAITTIME%") do set "WAITTIME=%%W"
set /a WAITTIME=WAITTIME >nul 2>&1
if %WAITTIME% LSS 1 set "WAITTIME=5"
if %WAITTIME% GTR 120 set "WAITTIME=5"

REM If DEBUG mode on, default WAITTIME to 3 seconds, otherwise 5
if "%DEBUG%"=="1" (
    if "%WAITTIME%"=="5" set "WAITTIME=3"
)

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
        REM Auto-close stray windows after short delay; escape inner quotes for WINDOWTITLE filter
        start "" /min cmd /c "timeout /t 10 /nobreak >nul 2>&1 & taskkill /fi \"WINDOWTITLE eq Updating Executor\" /f >nul 2>&1"
    )
)

:: =====================================================
:: Generate arrow_menu.ps1 helper if needed (before boot)
:: =====================================================
if not exist "%MENU_HELPER%" (
    if "%DEBUG%"=="1" echo [DEBUG] Generating arrow_menu.ps1 helper...
    call :GENERATE_MENU_HELPER
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
:: Boot Menu with Settings and Wipe Options
:: =====================================================
:BOOT_MENU
cls
echo ========================================
echo          UPDATING EXECUTOR - BOOT MENU
echo ========================================
echo.
echo [C] Continue normally (default)
echo [S] Settings
if "%ENABLEWIPE%"=="1" echo [W] Wipe entire run_space directory and exit
REM Build menu options array
set "menu_items=Continue normally"
set "menu_items=!menu_items!;Settings"
if "%ENABLEWIPE%"=="1" set "menu_items=!menu_items!;Wipe run_space and exit"
set "menu_items=!menu_items!;Quit"

echo.
echo Use UP/DOWN arrows to navigate, ENTER to select:
echo.

if "%DEBUG%"=="1" echo [DEBUG] menu_items=!menu_items!
if "%DEBUG%"=="1" echo [DEBUG] MENU_HELPER=%MENU_HELPER%

REM Call PowerShell arrow menu
set "menu_out=%RUN_DIR%\menu_result.tmp"
set "menu_debug_log=%LOG_DIR%\menu_navigation.log"
if exist "%menu_out%" del "%menu_out%"
if exist "%menu_debug_log%" del "%menu_debug_log%"
set "menu_timeout=0"
if "%AUTOINPUT%"=="1" set "menu_timeout=%WAITTIME%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MENU_HELPER%" -Options "!menu_items!" -Title "BOOT MENU" -DefaultIndex 0 -TimeoutSeconds !menu_timeout! -OutputFile "%menu_out%" -DebugLogFile "%menu_debug_log%"
set /p menu_idx=<"%menu_out%"
if exist "%menu_out%" del "%menu_out%"

REM Map selection to choice
set "boot_choice=C"
if "!menu_idx!"=="0" set "boot_choice=C"
if "!menu_idx!"=="1" set "boot_choice=S"
if "%ENABLEWIPE%"=="1" (
    if "!menu_idx!"=="2" set "boot_choice=W"
    if "!menu_idx!"=="3" set "boot_choice=Q"
) else (
    if "!menu_idx!"=="2" set "boot_choice=Q"
)

if /i "%boot_choice%"=="S" goto :SETTINGS_MENU
if /i "%boot_choice%"=="W" (
    if "%ENABLEWIPE%"=="1" goto :WIPE_NEIGHBORS
)
if /i "%boot_choice%"=="Q" (
    echo [INFO] Exiting without running.
    goto :END
)

REM Default to continue (C)
goto :SKIP_BOOT

:: =====================================================
:: Settings Menu
:: =====================================================
:SETTINGS_MENU
cls
echo ========================================
echo          SETTINGS MENU
echo ========================================
echo.
echo Current Settings:
echo [1] Debug Mode:           %DEBUG% (0=OFF, 1=ON)
echo [2] Auto Input:           %AUTOINPUT% (0=disabled, 1=enabled)
echo [3] Wait Time:            %WAITTIME% seconds
echo [4] Enable Wipe Option:   %ENABLEWIPE% (0=disabled, 1=enabled)
echo [5] Enable Previous Code: %ENABLEPREVIOUSCODE% (0=disabled, 1=enabled)
echo [6] Log Level:            %LOGLEVEL% (1=minimal, 2=normal, 3=verbose)
echo.
echo [B] Back to Boot Menu
echo [S] Save and Continue
echo [Q] Quit
echo.
echo Enter choice (1-6, B, S, or Q):
set "settings_choice="
set /p "settings_choice="

if "%settings_choice%"=="" goto :SETTINGS_MENU
set "settings_choice=%settings_choice:~0,1%"

if /i "%settings_choice%"=="1" goto :SETTINGS_EDIT_DEBUG
if /i "%settings_choice%"=="2" goto :SETTINGS_EDIT_AUTOINPUT
if /i "%settings_choice%"=="3" goto :SETTINGS_EDIT_WAITTIME
if /i "%settings_choice%"=="4" goto :SETTINGS_EDIT_ENABLEWIPE
if /i "%settings_choice%"=="5" goto :SETTINGS_EDIT_ENABLEPREVIOUSCODE
if /i "%settings_choice%"=="6" goto :SETTINGS_EDIT_LOGLEVEL
if /i "%settings_choice%"=="B" goto :BOOT_MENU
if /i "%settings_choice%"=="S" goto :SETTINGS_SAVE
if /i "%settings_choice%"=="Q" goto :END

goto :SETTINGS_MENU

:SETTINGS_EDIT_DEBUG
cls
echo ========================================
echo DEBUG MODE SETTING
echo ========================================
echo.
echo Current value: %DEBUG%
echo 0 = Debug OFF (normal operation)
echo 1 = Debug ON (verbose output)
echo.
set "new_value="
set /p "new_value=Enter new value (0 or 1, blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="0" (
    set "DEBUG=0"
    call :UPDATE_SETTING DEBUG 0
    goto :SETTINGS_MENU
)
if "%new_value%"=="1" (
    set "DEBUG=1"
    call :UPDATE_SETTING DEBUG 1
    goto :SETTINGS_MENU
)
echo [ERROR] Invalid input. Please enter 0 or 1.
pause
goto :SETTINGS_EDIT_DEBUG

:SETTINGS_EDIT_AUTOINPUT
cls
echo ========================================
echo AUTO INPUT SETTING
echo ========================================
echo.
echo Current value: %AUTOINPUT%
echo 0 = Disabled (unlimited time to choose)
echo 1 = Enabled (timeout with countdown)
echo.
set "new_value="
set /p "new_value=Enter new value (0 or 1, blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="0" (
    set "AUTOINPUT=0"
    call :UPDATE_SETTING AUTOINPUT 0
    goto :SETTINGS_MENU
)
if "%new_value%"=="1" (
    set "AUTOINPUT=1"
    call :UPDATE_SETTING AUTOINPUT 1
    goto :SETTINGS_MENU
)
echo [ERROR] Invalid input. Please enter 0 or 1.
pause
goto :SETTINGS_EDIT_AUTOINPUT

:SETTINGS_EDIT_WAITTIME
cls
echo ========================================
echo WAIT TIME SETTING
echo ========================================
echo.
echo Current value: %WAITTIME% seconds
echo Enter the number of seconds to wait for input
echo (minimum 1, maximum 60)
echo.
set "new_value="
set /p "new_value=Enter new wait time (blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="0" goto :WAITTIME_INVALID
if %new_value% LSS 1 goto :WAITTIME_INVALID
if %new_value% GTR 60 goto :WAITTIME_INVALID
set "WAITTIME=%new_value%"
call :UPDATE_SETTING WAITTIME %new_value%
goto :SETTINGS_MENU

:WAITTIME_INVALID
echo [ERROR] Invalid input. Please enter a value between 1 and 60.
pause
goto :SETTINGS_EDIT_WAITTIME

:SETTINGS_EDIT_ENABLEWIPE
cls
echo ========================================
echo ENABLE WIPE OPTION SETTING
echo ========================================
echo.
echo Current value: %ENABLEWIPE%
echo 0 = Disabled (remove W option from boot menu)
echo 1 = Enabled (show W option at boot menu)
echo.
set "new_value="
set /p "new_value=Enter new value (0 or 1, blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="0" (
    set "ENABLEWIPE=0"
    call :UPDATE_SETTING ENABLEWIPE 0
    goto :SETTINGS_MENU
)
if "%new_value%"=="1" (
    set "ENABLEWIPE=1"
    call :UPDATE_SETTING ENABLEWIPE 1
    goto :SETTINGS_MENU
)
echo [ERROR] Invalid input. Please enter 0 or 1.
pause
goto :SETTINGS_EDIT_ENABLEWIPE

:SETTINGS_EDIT_ENABLEPREVIOUSCODE
cls
echo ========================================
echo ENABLE PREVIOUS CODE SETTING
echo ========================================
echo.
echo Current value: %ENABLEPREVIOUSCODE%
echo 0 = Disabled (no [P] option to run previous code)
echo 1 = Enabled (show [P] option to rerun previously executed code)
echo.
set "new_value="
set /p "new_value=Enter new value (0 or 1, blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="0" (
    set "ENABLEPREVIOUSCODE=0"
    call :UPDATE_SETTING ENABLEPREVIOUSCODE 0
    goto :SETTINGS_MENU
)
if "%new_value%"=="1" (
    set "ENABLEPREVIOUSCODE=1"
    call :UPDATE_SETTING ENABLEPREVIOUSCODE 1
    goto :SETTINGS_MENU
)
echo [ERROR] Invalid input. Please enter 0 or 1.
pause
goto :SETTINGS_EDIT_ENABLEPREVIOUSCODE

:SETTINGS_EDIT_LOGLEVEL
cls
echo ========================================
echo LOG LEVEL SETTING
echo ========================================
echo.
echo Current value: %LOGLEVEL%
echo 1 = Minimal (only errors and important info)
echo 2 = Normal (standard logging)
echo 3 = Verbose (detailed debug output)
echo.
set "new_value="
set /p "new_value=Enter new value (1, 2, or 3, blank to cancel): "
if "%new_value%"=="" goto :SETTINGS_MENU
if "%new_value%"=="1" (
    set "LOGLEVEL=1"
    call :UPDATE_SETTING LOGLEVEL 1
    goto :SETTINGS_MENU
)
if "%new_value%"=="2" (
    set "LOGLEVEL=2"
    call :UPDATE_SETTING LOGLEVEL 2
    goto :SETTINGS_MENU
)
if "%new_value%"=="3" (
    set "LOGLEVEL=3"
    call :UPDATE_SETTING LOGLEVEL 3
    goto :SETTINGS_MENU
)
echo [ERROR] Invalid input. Please enter 1, 2, or 3.
pause
goto :SETTINGS_EDIT_LOGLEVEL

:SETTINGS_SAVE
echo.
echo [INFO] Settings saved to %SETTINGS_FILE%
echo.
pause
goto :BOOT_MENU

:UPDATE_SETTING
setlocal enabledelayedexpansion
set "KEY=%~1"
set "VALUE=%~2"
set "TEMPFILE=%SETTINGS_FILE%.tmp"

REM Create temp file with updated setting
(
    for /f "usebackq delims=" %%L in ("%SETTINGS_FILE%") do (
        set "LINE=%%L"
        if "!LINE:~0,1!"=="!" (
            echo !LINE!
        ) else if "!LINE:~0,1!"=="#" (
            echo !LINE!
        ) else if "!LINE:~0,1!"=="" (
            echo !LINE!
        ) else (
            for /f "tokens=1 delims==" %%K in ("!LINE!") do (
                if /i "%%K"=="!KEY!" (
                    echo !KEY!=!VALUE!
                ) else (
                    echo !LINE!
                )
            )
        )
    )
) > "!TEMPFILE!"

REM Replace original file
del "%SETTINGS_FILE%"
ren "!TEMPFILE!" "settings.ini"
endlocal
exit /b

:WIPE_NEIGHBORS
setlocal EnableDelayedExpansion
echo.
echo [INFO] Wiping workspace directory: %WORKDIR%
echo [INFO] Preserving: run.bat, _debug/, run_space/, *.ini, *.md

REM NOTE: We don't log during wipe since run_space is being deleted

REM Initialize counters
set "DELETED_FILES=0"
set "DELETED_DIRS=0"

REM DEBUG MODE - List all files and directories before wiping
if "%DEBUG%"=="1" (
    echo.
    echo [DEBUG] Files to be deleted:
    cd /d "%WORKDIR%"
    for %%F in (*.*) do (
        if not "%%F"=="run.bat" (
            if not "%%~xF"==".ini" (
                if not "%%~xF"==".md" (
                    echo [DEBUG]   %%F
                )
            )
        )
    )
    echo.
    echo [DEBUG] Directories to be deleted:
    for /d %%D in (*) do (
        if not "%%D"=="_debug" if not "%%D"=="run_space" (
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

REM Delete all files in WORKDIR except run.bat, *.ini, *.md
cd /d "%WORKDIR%"
set "FILE_COUNT=0"
for %%F in (*.*) do (
    if not "%%F"=="run.bat" (
        if not "%%~xF"==".ini" (
            if not "%%~xF"==".md" (
                del "%%F" >nul 2>&1
                set /a "FILE_COUNT+=1"
                if "%DEBUG%"=="1" echo [OK] %%F deleted.
            )
        )
    )
)
if !FILE_COUNT! gtr 0 (
    set /a "DELETED_FILES=!FILE_COUNT!"
)

REM Delete all subdirectories except _debug and run_space
set "DIR_COUNT=0"
for /d %%D in (*) do (
    if not "%%D"=="_debug" if not "%%D"=="run_space" (
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
echo [INFO] Workspace cleaned. Preserved: run.bat, _debug/, run_space/
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
:: Show clipboard content in formatted 70-char width array
:: =====================================================
echo.
echo ================== CLIPBOARD CONTENT ^(70 char width^) ====================
set "line_count=0"
for /f "usebackq delims=" %%L in ("%CLIP_TXT%") do (
    set "line=%%L"
    REM Replace newlines with space to get one continuous string
    set "full_clip=!full_clip! !line!"
)
REM Remove spaces to get continuous string, then format in 70-char lines
set "full_clip=%full_clip: =%"
if defined full_clip (
    set "pos=0"
    set "line_count=0"
    :format_loop
    if !line_count! lss 50 (
        set "line=!full_clip:~!pos!,70!"
        if defined line (
            echo !line!
            set /a pos+=70
            set /a line_count+=1
            goto :format_loop
        )
    )
) else (
    echo [EMPTY]
)
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
cls
echo ========================================
echo          MAIN MENU
echo ========================================
REM Build main menu options
set "main_items=Run clipboard as script"
set "main_items=!main_items!;Edit before running"
set "main_items=!main_items!;Detect file type"
if "%ENABLEPREVIOUSCODE%"=="1" if exist "%RUN_DIR%\previous_code.txt" set "main_items=!main_items!;Run previous code"
set "main_items=!main_items!;Settings"
set "main_items=!main_items!;Quit"

echo.
echo Use UP/DOWN arrows to navigate, ENTER to select:
echo.

if "%DEBUG%"=="1" echo [DEBUG] main_items=!main_items!
if "%DEBUG%"=="1" echo [DEBUG] MENU_HELPER=%MENU_HELPER%

REM Call PowerShell arrow menu
set "menu_out=%RUN_DIR%\menu_result.tmp"
set "menu_debug_log=%LOG_DIR%\menu_navigation.log"
if exist "%menu_out%" del "%menu_out%"
if exist "%menu_debug_log%" del "%menu_debug_log%"
set "menu_timeout=0"
if "%AUTOINPUT%"=="1" set "menu_timeout=%WAITTIME%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MENU_HELPER%" -Options "!main_items!" -Title "MAIN MENU" -DefaultIndex 0 -TimeoutSeconds !menu_timeout! -OutputFile "%menu_out%" -DebugLogFile "%menu_debug_log%"
if exist "%menu_out%" (
    set /p menu_idx=<"%menu_out%"
    del "%menu_out%"
)

REM Map selection to choice letter
set "choice="
set "has_prev=0"
if "%ENABLEPREVIOUSCODE%"=="1" if exist "%RUN_DIR%\previous_code.txt" set "has_prev=1"

REM If menu index was returned, use it
if defined menu_idx (
    if "!menu_idx!"=="0" set "choice=R"
    if "!menu_idx!"=="1" set "choice=E"
    if "!menu_idx!"=="2" set "choice=D"
    if "!has_prev!"=="1" (
        if "!menu_idx!"=="3" set "choice=P"
        if "!menu_idx!"=="4" set "choice=S"
        if "!menu_idx!"=="5" set "choice=Q"
    ) else (
        if "!menu_idx!"=="3" set "choice=S"
        if "!menu_idx!"=="4" set "choice=Q"
    )
)

if /i "%choice%"=="S" goto :SETTINGS_MENU
if /i "%choice%"=="Q" goto :END

REM Handle Edit mode - open clipboard file in editor before running
if /i "%choice%"=="E" (
    if "%DEBUG%"=="1" echo [DEBUG] Edit mode selected - opening file in editor
    echo.
    echo [INFO] Opening code in editor...
    if exist "%CLIP_TXT%" (
        REM Use /wait flag to block until Notepad closes
        start "" /wait notepad "%CLIP_TXT%"
        echo [INFO] Editor closed. Executing modified code...
    ) else (
        echo [ERROR] Clipboard file not found.
        pause
        goto :MENU
    )
    set "choice=R"
)

:: =====================================================
:: Detect file type from clipboard content
:: =====================================================
:DETECT_AND_RUN
if "%DEBUG%"=="1" echo [DEBUG] Entered :DETECT_AND_RUN - choice=%choice%

if /i "%choice%"=="P" (
    if not "%ENABLEPREVIOUSCODE%"=="1" (
        echo [ERROR] Previous code feature is disabled.
        pause
        goto :MENU
    )
    if not exist "%RUN_DIR%\previous_code.txt" (
        echo [ERROR] No previous code found.
        pause
        goto :MENU
    )
    echo.
    echo [INFO] Loading previously executed code...
    type "%RUN_DIR%\previous_code.txt" > "%CLIP_TXT%"
    set "choice=R"
    goto :DETECT_AND_RUN
)

if /i "%choice%"=="D" (
    echo.
    echo Analyzing clipboard content...
    setlocal enabledelayedexpansion
    set /p "first_line=" < "%CLIP_TXT%"
    
    if "!first_line!"=="" echo [INFO] File appears to be empty & goto :D_CHOICE_DONE
    
    echo First line: !first_line!
    if "!first_line:~0,1!"=="@" echo [DETECT] Batch/CMD script detected & goto :D_CHOICE_DONE
    if "!first_line:~0,1!"==":" echo [DETECT] Batch/CMD script detected & goto :D_CHOICE_DONE
    if "!first_line:~0,1!"=="#" (
        if "!first_line:~2,6!"=="python" echo [DETECT] Python script detected & goto :D_CHOICE_DONE
        if "!first_line:~2,4!"=="bash" echo [DETECT] Bash script detected & goto :D_CHOICE_DONE
        echo [DETECT] Shell script detected
        goto :D_CHOICE_DONE
    )
    if "!first_line:~0,2!"=="-*-" echo [DETECT] Could be various script types & goto :D_CHOICE_DONE
    echo [DETECT] Unknown type - will attempt execution
    
    :D_CHOICE_DONE
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
    echo Opening file in Notepad for editing...
    start "" /wait notepad "%RUN_FILE%"
    echo Edit complete. Continuing to run the code.
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

REM Save to previous code history if successful and feature is enabled
if !exitCode! equ 0 (
    if "%ENABLEPREVIOUSCODE%"=="1" (
        copy "%RUN_FILE%" "%RUN_DIR%\previous_code.txt" >nul 2>&1
        if "%DEBUG%"=="1" echo [DEBUG] Code saved to previous_code.txt
    )
)

REM Log execution result
if !exitCode! equ 0 (
    (echo [EXECUTION] Success - File: %RUN_FILE% - %logdate% %logtime%) >> "%LOG_IMPORTANT%"
) else (
    (echo [EXECUTION] Failed with code !exitCode! - File: %RUN_FILE% - %logdate% %logtime%) >> "%LOG_IMPORTANT%"
)
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
    REM Wait for user input - 10 second timeout for Y/N choice
    echo Press Y within 10 seconds to run another code, or N to exit:
    choice /C YN /T 10 /D N /M ""
    set "restart=%ERRORLEVEL%"
    
    REM ERRORLEVEL: 1=Y, 2=N, timeout defaults to N (2)
    if "%restart%"=="1" (
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

:: =====================================================
:: Utility Subroutines
:: =====================================================

:CREATE_BACKUP_REPORT
:: Create a report file next to the backup version
:: Usage: call :CREATE_BACKUP_REPORT "version" "reason"
setlocal
set "VERSION_NUM=%~1"
set "REASON=%~2"
set "REPORT_FILE=%DEBUG_BACKUPS%\report-v%VERSION_NUM%.log"

(
    echo ========================================
    echo BACKUP REPORT - Version %VERSION_NUM%
    echo ========================================
    echo.
    echo Date: %date% %time%
    echo Reason: %REASON%
    echo.
    echo Settings at backup time:
    echo   DEBUG=%DEBUG%
    echo   TIMEOUT=%TIMEOUT%
    echo   LOGLEVEL=%LOGLEVEL%
    echo   AUTOCLEAN=%AUTOCLEAN%
    echo   HALTONERROR=%HALTONERROR%
    echo   PERFMON=%PERFMON%
    echo   AUTOINPUT=%AUTOINPUT%
    echo   WAITTIME=%WAITTIME%
    echo   ENABLEWIPE=%ENABLEWIPE%
    echo   ENABLEPREVIOUSCODE=%ENABLEPREVIOUSCODE%
    echo.
    echo Backed up files:
    echo   run.bat ^(main executable^)
    echo   settings.ini ^(configuration^)
    echo.
    echo ========================================
) > "%REPORT_FILE%"

endlocal
goto :EOF

:CREATE_TEST_ENVIRONMENT
:: Create a testing copy of the parent directory in _debug\_testenv
:: Usage: call :CREATE_TEST_ENVIRONMENT
echo [INFO] Creating testing environment in _debug\_testenv...
if exist "%TEST_ENV%" (
    rmdir /s /q "%TEST_ENV%" >nul 2>&1
)
mkdir "%TEST_ENV%" 2>nul

REM Get parent directory (updatingExecutor's parent)
for %%A in ("%WORKDIR:~0,-1%") do set "PARENT_FOR_TEST=%%~dpA"

REM Copy entire parent directory to test environment
xcopy "%PARENT_FOR_TEST%*" "%TEST_ENV%\" /E /Y /EXCLUDE:"%WORKDIR%_testenv_exclude.txt" >nul 2>&1

echo [OK] Test environment created at: %TEST_ENV%
goto :EOF

:GENERATE_MENU_HELPER
> "%MENU_HELPER%"  echo param([string]$Options, [string]$Title="MENU", [int]$DefaultIndex=0, [int]$TimeoutSeconds=0, [string]$OutputFile, [string]$DebugLogFile)
>> "%MENU_HELPER%" echo if (-not $Options) { exit 1 }
>> "%MENU_HELPER%" echo $items = $Options -split ';'
>> "%MENU_HELPER%" echo if (-not $items -or $items.Length -eq 0) { exit 1 }
>> "%MENU_HELPER%" echo $idx = [Math]::Min([Math]::Max($DefaultIndex, 0), $items.Length - 1)
>> "%MENU_HELPER%" echo $deadline = if ($TimeoutSeconds -gt 0) { [DateTime]::UtcNow.AddSeconds($TimeoutSeconds) } else { $null }
>> "%MENU_HELPER%" echo function Write-Row { param([string]$Text, [bool]$Selected) if ($Selected) { Write-Host "> $Text" -ForegroundColor Cyan } else { Write-Host "  $Text" } }
>> "%MENU_HELPER%" echo function Log-Debug { param([string]$Message) if (-not $DebugLogFile) { return } $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"; $dir = Split-Path $DebugLogFile -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force ^| Out-Null }; "$stamp `t $Message" ^| Out-File -FilePath $DebugLogFile -Append -Encoding ASCII }
>> "%MENU_HELPER%" echo try { [Console]::CursorVisible = $false } catch {}
>> "%MENU_HELPER%" echo try {
>> "%MENU_HELPER%" echo     while ($true) {
>> "%MENU_HELPER%" echo         Clear-Host
>> "%MENU_HELPER%" echo         if ($Title) { Write-Host $Title; Write-Host "" }
>> "%MENU_HELPER%" echo         for ($i = 0; $i -lt $items.Length; $i++) { Write-Row -Text $items[$i] -Selected ($i -eq $idx) }
>> "%MENU_HELPER%" echo         if ($deadline -and [DateTime]::UtcNow -gt $deadline) { Log-Debug "Timeout -> $idx"; break }
>> "%MENU_HELPER%" echo         if ([Console]::KeyAvailable) {
>> "%MENU_HELPER%" echo             $key = [Console]::ReadKey($true)
>> "%MENU_HELPER%" echo             switch ($key.Key) {
>> "%MENU_HELPER%" echo                 'UpArrow'   { $idx = if ($idx -gt 0) { $idx - 1 } else { $items.Length - 1 }; Log-Debug "Up -> $idx" }
>> "%MENU_HELPER%" echo                 'DownArrow' { $idx = if ($idx -lt $items.Length - 1) { $idx + 1 } else { 0 }; Log-Debug "Down -> $idx" }
>> "%MENU_HELPER%" echo                 'Enter'     { Log-Debug "Enter -> $idx"; break }
>> "%MENU_HELPER%" echo                 'Escape'    { Log-Debug "Escape -> $idx"; break }
>> "%MENU_HELPER%" echo             }
>> "%MENU_HELPER%" echo         } else { Start-Sleep -Milliseconds 100 }
>> "%MENU_HELPER%" echo     }
>> "%MENU_HELPER%" echo }
>> "%MENU_HELPER%" echo finally { try { [Console]::CursorVisible = $true } catch {} }
>> "%MENU_HELPER%" echo if ($OutputFile) { $idx ^| Out-File -FilePath $OutputFile -Encoding ASCII -Force }
>> "%MENU_HELPER%" echo exit 0
exit /b

:: =====================================================
:: Logging Subroutines
:: =====================================================

:LOGIMPORTANT
:: Log to important.log with timestamp
:: Usage: (echo %logdate% %logtime% - %1) >> "%LOG_IMPORTANT%"
if "%LOGLEVEL%"=="1" goto :EOF
echo [%logdate% %logtime%] %~1 >> "%LOG_IMPORTANT%"
goto :EOF

:LOGINPUT
:: Log user input to input.log
echo [%logdate% %logtime%] User input: %~1 >> "%LOG_INPUT%"
goto :EOF

:LOGTERMINAL
:: Log to terminal.log if enabled
if "%LOGLEVEL%"=="3" echo [%logdate% %logtime%] %~1 >> "%LOG_TERMINAL%"
goto :EOF

