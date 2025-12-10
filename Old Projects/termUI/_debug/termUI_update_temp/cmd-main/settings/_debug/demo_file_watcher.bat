@echo off
REM Demo: File Watcher Feature
REM This demonstrates the automatic reload when settings.ini is modified externally

echo ============================================
echo   FILE WATCHER DEMONSTRATION
echo ============================================
echo.
echo This demo shows how Settings Manager automatically
echo detects when settings.ini is edited externally.
echo.
echo STEPS:
echo 1. Settings Manager will start
echo 2. Wait for the menu to appear
echo 3. Open settings.ini in Notepad
echo 4. Edit a value and save
echo 5. Return to Settings Manager and press 1 to see menu
echo 6. Watch for "EXTERNAL CHANGE DETECTED" message
echo.
pause

cd automated_testing_environment

REM Create initial settings
echo # Settings Configuration File > settings.ini
echo [General] >> settings.ini
echo myValue=original  # Initial value >> settings.ini

echo.
echo Starting Settings Manager...
echo After it loads, edit 'settings.ini' in Notepad
echo Change 'myValue=original' to 'myValue=MODIFIED'
echo Then go back to Settings Manager and enter: 1
echo.
pause

REM Start notepad with the settings file
start notepad settings.ini

REM Start Settings Manager (will wait for input)
run.bat

cd ..
