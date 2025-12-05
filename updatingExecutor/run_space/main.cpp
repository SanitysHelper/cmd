#include <iostream>
#include <fstream>
#include <string>
ECHO is off.
int main() {
    const std::string filename = "saved_input.txt";
ECHO is off.
    std::cout << "Enter something to save: ";
ECHO is off.
    std::string userInput;
    std::getline(std::cin, userInput);
ECHO is off.
    if (userInput.empty()) {
        std::cout << "[INFO] No input provided. Nothing was saved.\n";
        return 0;
    }
ECHO is off.
    std::ofstream outFile(filename, std::ios::app);
    if (outFile) {
        std::cout << "[ERROR] Could not open file \"" ^<^< filename ^<^< "\" for writing.\n";
        return 1;
    }
ECHO is off.
    outFile << userInput << '\n';
ECHO is off.
    if (outFile.good()) {
        std::cout << "[ERROR] Failed to write to \"" ^<^< filename ^<^< "\".\n";
        return 1;
    }
ECHO is off.
    std::cout << "[OK] Added input to \"" ^<^< filename ^<^< "\".\n";
    return 0;
}
