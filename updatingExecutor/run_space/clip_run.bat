@echo off
setlocal

:: Names for generated files
set "CPP_FILE=main.cpp"
set "EXE_FILE=save_input.exe"

echo [INFO] Generating %CPP_FILE%...

> "%CPP_FILE%"  echo #include ^<iostream^>
>>"%CPP_FILE%" echo #include ^<fstream^>
>>"%CPP_FILE%" echo #include ^<string^>
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo int main() {
>>"%CPP_FILE%" echo     const std::string filename = "saved_input.txt";
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     std::cout ^<^< "Enter something to save: ";
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     std::string userInput;
>>"%CPP_FILE%" echo     std::getline(std::cin, userInput);
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     if (userInput.empty()) {
>>"%CPP_FILE%" echo         std::cout ^<^< "[INFO] No input provided. Nothing was saved.\n";
>>"%CPP_FILE%" echo         return 0;
>>"%CPP_FILE%" echo     }
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     std::ofstream outFile(filename, std::ios::app);
>>"%CPP_FILE%" echo     if (!outFile) {
>>"%CPP_FILE%" echo         std::cout ^<^< "[ERROR] Could not open file \"" ^<^< filename ^<^< "\" for writing.\n";
>>"%CPP_FILE%" echo         return 1;
>>"%CPP_FILE%" echo     }
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     outFile ^<^< userInput ^<^< '\n';
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     if (!outFile.good()) {
>>"%CPP_FILE%" echo         std::cout ^<^< "[ERROR] Failed to write to \"" ^<^< filename ^<^< "\".\n";
>>"%CPP_FILE%" echo         return 1;
>>"%CPP_FILE%" echo     }
>>"%CPP_FILE%" echo
>>"%CPP_FILE%" echo     std::cout ^<^< "[OK] Added input to \"" ^<^< filename ^<^< "\".\n";
>>"%CPP_FILE%" echo     return 0;
>>"%CPP_FILE%" echo }

echo [INFO] Generated %CPP_FILE%.
echo.

:: Check for g++
where g++ >nul 2>&1
if errorlevel 1 (
    echo [ERROR] g++ not found in PATH.
    echo Install MinGW / a C++ compiler and add g++ to PATH.
    pause
    exit /b 1
)

echo [INFO] Compiling %CPP_FILE%...
g++ "%CPP_FILE%" -o "%EXE_FILE%"
if errorlevel 1 (
    echo [ERROR] Compilation failed.
    pause
    exit /b 1
)

echo [INFO] Compilation successful: %EXE_FILE%.
echo.
echo [RUN] Starting %EXE_FILE%...
echo.

"%EXE_FILE%"

echo.
echo [EXIT] Done.
endlocal
exit /b 0

