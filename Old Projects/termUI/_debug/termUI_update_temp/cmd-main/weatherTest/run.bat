@echo off
setlocal
set "ROOT=%~dp0"
if not exist "%ROOT%bin\WeatherTest.exe" (
    echo [INFO] Executable not found, building first...
    call "%ROOT%compile.bat"
    if errorlevel 1 exit /b 1
)
start "" "%ROOT%bin\WeatherTest.exe"
endlocal
