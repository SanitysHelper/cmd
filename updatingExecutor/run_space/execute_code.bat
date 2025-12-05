@echo off
setlocal enabledelayedexpansion

:: execute_code.bat - Universal code executor
:: Usage: execute_code.bat <file>
:: Detects language and runs with appropriate interpreter

set "FILE=%~1"

if not defined FILE (
    echo [ERROR] No file specified
    exit /b 1
)

if not exist "%FILE%" (
    echo [ERROR] File not found: %FILE%
    exit /b 1
)

set "EXT=%~x1"

REM Detect language by extension and run
if /i "%EXT%"==".bat" (
    echo [RUN] Batch script detected
    call "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".cmd" (
    echo [RUN] CMD script detected
    call "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".ps1" (
    echo [RUN] PowerShell script detected
    powershell -NoProfile -ExecutionPolicy Bypass -File "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".py" (
    echo [RUN] Python script detected
    python "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".c" (
    echo [RUN] C source detected - compiling...
    set "COMPILED=%~n1.exe"
    where gcc >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] gcc not found in PATH
        exit /b 1
    )
    gcc "%FILE%" -o "!COMPILED!" 
    if errorlevel 1 (
        echo [ERROR] Compilation failed
        exit /b 1
    )
    echo [RUN] Running compiled executable...
    call "!COMPILED!"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".cpp" (
    echo [RUN] C++ source detected - compiling...
    set "COMPILED=%~n1.exe"
    where g++ >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] g++ not found in PATH
        exit /b 1
    )
    g++ "%FILE%" -o "!COMPILED!"
    if errorlevel 1 (
        echo [ERROR] Compilation failed
        exit /b 1
    )
    echo [RUN] Running compiled executable...
    call "!COMPILED!"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".js" (
    echo [RUN] JavaScript detected
    node "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".lua" (
    echo [RUN] Lua script detected
    lua "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".rb" (
    echo [RUN] Ruby script detected
    ruby "%FILE%"
    exit /b !ERRORLEVEL!
)

if /i "%EXT%"==".sh" (
    echo [RUN] Shell script detected
    bash "%FILE%"
    exit /b !ERRORLEVEL!
)

echo [ERROR] Unknown file type: %EXT%
echo Supported: .bat, .cmd, .ps1, .py, .c, .cpp, .js, .lua, .rb, .sh
exit /b 1

endlocal
