@echo off
setlocal enabledelayedexpansion
set "FILE=%~1"
if not defined FILE (echo [ERROR] No file specified & exit /b 1)
if not exist "%FILE%" (echo [ERROR] File not found: %FILE% & exit /b 1)
set "EXT=%~x1"

REM Batch/CMD
if /i "%EXT%"==".bat" (echo [RUN] Batch script detected & call "%FILE%" & exit /b !ERRORLEVEL!)
if /i "%EXT%"==".cmd" (echo [RUN] CMD script detected & call "%FILE%" & exit /b !ERRORLEVEL!)

REM PowerShell
if /i "%EXT%"==".ps1" (echo [RUN] PowerShell script detected & powershell -NoProfile -ExecutionPolicy Bypass -File "%FILE%" & exit /b !ERRORLEVEL!)

REM Python
if /i "%EXT%"==".py" (echo [RUN] Python script detected & python "%FILE%" & exit /b !ERRORLEVEL!)

REM JavaScript
if /i "%EXT%"==".js" (echo [RUN] JavaScript detected & node "%FILE%" & exit /b !ERRORLEVEL!)

REM Lua
if /i "%EXT%"==".lua" (echo [RUN] Lua script detected & lua "%FILE%" & exit /b !ERRORLEVEL!)

REM Ruby
if /i "%EXT%"==".rb" (echo [RUN] Ruby script detected & ruby "%FILE%" & exit /b !ERRORLEVEL!)

REM Shell
if /i "%EXT%"==".sh" (echo [RUN] Shell script detected & bash "%FILE%" & exit /b !ERRORLEVEL!)

REM C - simplified without compilation
if /i "%EXT%"==".c" (echo [ERROR] C compilation not supported in generated executor & exit /b 1)
if /i "%EXT%"==".cpp" (echo [ERROR] C++ compilation not supported in generated executor & exit /b 1)

echo [ERROR] Unknown file type: %EXT%
echo Supported: .bat, .cmd, .ps1, .py, .js, .lua, .rb, .sh
exit /b 1
