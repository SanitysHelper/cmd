@echo off
setlocal

REM Names for generated files
set "CPP_FILE=main.cpp"
set "EXE_FILE=save_input.exe"

REM ----------------------------------------------------------
REM Check for PowerShell
REM ----------------------------------------------------------
where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell not found. This script requires PowerShell.
    pause
    exit /b 1
)

REM ----------------------------------------------------------
REM Generate main.cpp using PowerShell here-string
REM ----------------------------------------------------------
powershell -NoLogo -NoProfile -Command ^
"$code = @'
#include <iostream>
#include <fstream>
#include <string>

int main() {
    const std::string filename = \"saved_input.txt\";

    std::cout << \"Enter something to save: \";

    std::string userInput;
    std::getline(std::cin, userInput);

    if (userInput.empty()) {
        std::cout << \"[INFO] No input provided. Nothing was saved.\n\";
        return 0;
    }

    std::ofstream outFile(filename, std::ios::app);
    if (!outFile) {
        std::cout << \"[ERROR] Could not open file \\\"\" << filename << \"\\\" for writing.\n\";
        return 1;
    }

    outFile << userInput << '\\n';

    if (!outFile.good()) {
        std::cout << \"[ERROR] Failed to write to \\\"\" << filename << \"\\\".\n\";
        return 1;
    }

    std::cout << \"[OK] Added input to \\\"\" << filename << \"\\\".\n\";
    return 0;
}
'@; Set-Content -Path '%CPP_FILE%' -Value $code -Encoding UTF8"

if errorlevel 1 (
    echo [ERROR] Failed to generate %CPP_FILE%.
    pause
    exit /b 1
)

echo [INFO] Generated %CPP_FILE%.

REM ----------------------------------------------------------
REM Check for g++
REM ----------------------------------------------------------
where g++ >nul 2>&1
if errorlevel 1 (
    echo [ERROR] g++ not found in PATH.
    echo Install MinGW or a similar compiler, then try again.
    pause
    exit /b 1
)

REM ----------------------------------------------------------
REM Compile main.cpp -> save_input.exe
REM ----------------------------------------------------------
echo [INFO] Compiling %CPP_FILE%...
g++ "%CPP_FILE%" -o "%EXE_FILE%"
if errorlevel 1 (
    echo [ERROR] Compilation failed.
    pause
    exit /b 1
)

echo [INFO] Compilation successful: %EXE_FILE%.

REM ----------------------------------------------------------
REM Run the program
REM ----------------------------------------------------------
echo.
echo [RUN] Starting %EXE_FILE%...
echo.
"%EXE_FILE%"

echo.
echo [EXIT] Done.
pause

endlocal
exit /b 0
