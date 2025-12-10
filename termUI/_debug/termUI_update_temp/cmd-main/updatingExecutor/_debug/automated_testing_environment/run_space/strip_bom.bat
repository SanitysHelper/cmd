@echo off
setlocal
set "INPUT=%~1"
set "OUTPUT=%~2"
if not defined INPUT exit /b 1
if not defined OUTPUT exit /b 1
if not exist "%INPUT%" exit /b 1
more "%INPUT%" > "%OUTPUT%.tmp"
if errorlevel 1 exit /b 1
move /y "%OUTPUT%.tmp" "%OUTPUT%" >nul
exit /b 0
