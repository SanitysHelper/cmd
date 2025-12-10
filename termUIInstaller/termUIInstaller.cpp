/*
 * termUI Installer
 * Downloads termUI from GitHub and installs it to the user's system
 * Supports: Windows 10/11
 */

#include <windows.h>
#include <wininet.h>
#include <iostream>
#include <fstream>
#include <string>
#include <shlobj.h>
#include <direct.h>
#include <sys/stat.h>

#pragma comment(lib, "wininet.lib")
#pragma comment(lib, "shell32.lib")

// Configuration
const std::string GITHUB_REPO = "SanitysHelper/cmd";
const std::string GITHUB_BRANCH = "main";
const std::string TERMUI_FOLDER = "termUI";
const std::string DOWNLOAD_URL = "https://github.com/" + GITHUB_REPO + "/archive/refs/heads/" + GITHUB_BRANCH + ".zip";

// Function prototypes
void PrintHeader();
void PrintInfo(const std::string& message);
void PrintError(const std::string& message);
void PrintSuccess(const std::string& message);
bool DownloadFile(const std::string& url, const std::string& outputPath);
bool ExtractZip(const std::string& zipPath, const std::string& destPath);
bool CopyDirectory(const std::string& source, const std::string& dest);
bool PromptUser(const std::string& message);
std::string GetInstallPath();
void LogToFile(const std::string& message);

// Main function
int main(int argc, char* argv[]) {
    PrintHeader();
    
    LogToFile("termUI Installer started");
    
    // Step 1: Download termUI from GitHub
    PrintInfo("Downloading termUI from GitHub...");
    std::string zipPath = "termUI_download.zip";
    
    if (!DownloadFile(DOWNLOAD_URL, zipPath)) {
        PrintError("Failed to download termUI from GitHub");
        LogToFile("[ERROR] Download failed");
        system("pause");
        return 1;
    }
    
    PrintSuccess("Download complete!");
    LogToFile("Download successful");
    
    // Step 2: Extract the archive
    PrintInfo("Extracting archive...");
    std::string extractPath = "termUI_temp";
    
    if (!ExtractZip(zipPath, extractPath)) {
        PrintError("Failed to extract archive");
        LogToFile("[ERROR] Extraction failed");
        DeleteFileA(zipPath.c_str());
        system("pause");
        return 1;
    }
    
    PrintSuccess("Extraction complete!");
    LogToFile("Extraction successful");
    
    // Step 3: Prompt user for installation
    std::cout << std::endl;
    if (!PromptUser("Do you want to install termUI?")) {
        PrintInfo("Installation cancelled by user");
        LogToFile("Installation cancelled");
        
        // Cleanup
        DeleteFileA(zipPath.c_str());
        system(("rmdir /s /q \"" + extractPath + "\"").c_str());
        
        system("pause");
        return 0;
    }
    
    // Step 4: Get installation path
    std::string installPath = GetInstallPath();
    PrintInfo("Installing to: " + installPath);
    LogToFile("Installation path: " + installPath);
    
    // Step 5: Copy termUI folder to installation location
    PrintInfo("Copying files...");
    
    // The extracted folder will be cmd-main/termUI
    std::string sourcePath = extractPath + "\\cmd-" + GITHUB_BRANCH + "\\" + TERMUI_FOLDER;
    
    if (!CopyDirectory(sourcePath, installPath + "\\" + TERMUI_FOLDER)) {
        PrintError("Failed to copy files");
        LogToFile("[ERROR] File copy failed");
        
        // Cleanup
        DeleteFileA(zipPath.c_str());
        system(("rmdir /s /q \"" + extractPath + "\"").c_str());
        
        system("pause");
        return 1;
    }
    
    PrintSuccess("Installation complete!");
    LogToFile("Installation successful to: " + installPath);
    
    // Step 6: Cleanup temporary files
    PrintInfo("Cleaning up temporary files...");
    DeleteFileA(zipPath.c_str());
    system(("rmdir /s /q \"" + extractPath + "\"").c_str());
    
    // Step 7: Display completion message
    std::cout << std::endl;
    std::cout << "=============================================" << std::endl;
    std::cout << "  termUI has been installed successfully!" << std::endl;
    std::cout << "=============================================" << std::endl;
    std::cout << std::endl;
    std::cout << "Installation location: " << installPath << "\\" << TERMUI_FOLDER << std::endl;
    std::cout << std::endl;
    std::cout << "To run termUI, navigate to the installation directory and run:" << std::endl;
    std::cout << "  cd \"" << installPath << "\\" << TERMUI_FOLDER << "\"" << std::endl;
    std::cout << "  .\\run.bat" << std::endl;
    std::cout << std::endl;
    
    LogToFile("Installation completed successfully");
    
    system("pause");
    return 0;
}

// Function implementations
void PrintHeader() {
    std::cout << std::endl;
    std::cout << "=============================================" << std::endl;
    std::cout << "       termUI Installer v1.0.0" << std::endl;
    std::cout << "=============================================" << std::endl;
    std::cout << std::endl;
}

void PrintInfo(const std::string& message) {
    std::cout << "[INFO] " << message << std::endl;
}

void PrintError(const std::string& message) {
    std::cout << "[ERROR] " << message << std::endl;
}

void PrintSuccess(const std::string& message) {
    std::cout << "[SUCCESS] " << message << std::endl;
}

bool DownloadFile(const std::string& url, const std::string& outputPath) {
    LogToFile("Attempting to download from: " + url);
    
    HINTERNET hInternet = InternetOpenA("termUI Installer", INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    if (!hInternet) {
        LogToFile("[ERROR] Failed to initialize WinINet");
        return false;
    }
    
    HINTERNET hConnect = InternetOpenUrlA(hInternet, url.c_str(), NULL, 0, INTERNET_FLAG_RELOAD, 0);
    if (!hConnect) {
        LogToFile("[ERROR] Failed to connect to URL");
        InternetCloseHandle(hInternet);
        return false;
    }
    
    std::ofstream outFile(outputPath, std::ios::binary);
    if (!outFile) {
        LogToFile("[ERROR] Failed to create output file");
        InternetCloseHandle(hConnect);
        InternetCloseHandle(hInternet);
        return false;
    }
    
    char buffer[4096];
    DWORD bytesRead;
    DWORD totalBytes = 0;
    
    while (InternetReadFile(hConnect, buffer, sizeof(buffer), &bytesRead) && bytesRead > 0) {
        outFile.write(buffer, bytesRead);
        totalBytes += bytesRead;
        
        // Show progress every 100KB
        if (totalBytes % 102400 == 0) {
            std::cout << "  Downloaded: " << (totalBytes / 1024) << " KB\r" << std::flush;
        }
    }
    
    std::cout << "  Downloaded: " << (totalBytes / 1024) << " KB" << std::endl;
    LogToFile("Downloaded " + std::to_string(totalBytes) + " bytes");
    
    outFile.close();
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hInternet);
    
    return totalBytes > 0;
}

bool ExtractZip(const std::string& zipPath, const std::string& destPath) {
    LogToFile("Extracting " + zipPath + " to " + destPath);
    
    // Use PowerShell to extract the zip file
    std::string command = "powershell -NoProfile -ExecutionPolicy Bypass -Command \"Expand-Archive -Path '" + 
                         zipPath + "' -DestinationPath '" + destPath + "' -Force\"";
    
    int result = system(command.c_str());
    
    if (result == 0) {
        LogToFile("Extraction successful");
        return true;
    } else {
        LogToFile("[ERROR] PowerShell extraction failed with code: " + std::to_string(result));
        return false;
    }
}

bool CopyDirectory(const std::string& source, const std::string& dest) {
    LogToFile("Copying from " + source + " to " + dest);
    
    // Create destination directory
    _mkdir(dest.c_str());
    
    // Use robocopy for reliable directory copying
    std::string command = "robocopy \"" + source + "\" \"" + dest + "\" /E /NFL /NDL /NJH /NJS /NC /NS /NP";
    
    int result = system(command.c_str());
    
    // Robocopy return codes: 0-7 are success, 8+ are failures
    if (result < 8) {
        LogToFile("Copy successful");
        return true;
    } else {
        LogToFile("[ERROR] Robocopy failed with code: " + std::to_string(result));
        return false;
    }
}

bool PromptUser(const std::string& message) {
    std::cout << message << " (Y/N): ";
    std::string response;
    std::getline(std::cin, response);
    
    if (response.empty()) {
        return false;
    }
    
    char firstChar = std::tolower(response[0]);
    LogToFile("User prompt: " + message + " - Response: " + response);
    
    return (firstChar == 'y');
}

std::string GetInstallPath() {
    std::cout << std::endl;
    std::cout << "Select installation location:" << std::endl;
    std::cout << "  1. Current directory" << std::endl;
    std::cout << "  2. C:\\Program Files\\termUI" << std::endl;
    std::cout << "  3. User Documents folder" << std::endl;
    std::cout << "  4. Custom path" << std::endl;
    std::cout << std::endl;
    std::cout << "Enter choice (1-4): ";
    
    std::string choice;
    std::getline(std::cin, choice);
    
    if (choice == "1") {
        char currentPath[MAX_PATH];
        _getcwd(currentPath, MAX_PATH);
        LogToFile("Install path: Current directory - " + std::string(currentPath));
        return std::string(currentPath);
    }
    else if (choice == "2") {
        std::string path = "C:\\Program Files\\termUI";
        LogToFile("Install path: Program Files - " + path);
        return path;
    }
    else if (choice == "3") {
        char documentsPath[MAX_PATH];
        SHGetFolderPathA(NULL, CSIDL_PERSONAL, NULL, 0, documentsPath);
        std::string path = std::string(documentsPath) + "\\termUI";
        LogToFile("Install path: Documents - " + path);
        return path;
    }
    else if (choice == "4") {
        std::cout << "Enter custom installation path: ";
        std::string customPath;
        std::getline(std::cin, customPath);
        LogToFile("Install path: Custom - " + customPath);
        return customPath;
    }
    else {
        PrintInfo("Invalid choice, using current directory");
        char currentPath[MAX_PATH];
        _getcwd(currentPath, MAX_PATH);
        LogToFile("Install path: Default (current directory) - " + std::string(currentPath));
        return std::string(currentPath);
    }
}

void LogToFile(const std::string& message) {
    std::ofstream logFile("_debug\\logs\\installer.log", std::ios::app);
    if (logFile) {
        // Get timestamp
        SYSTEMTIME st;
        GetLocalTime(&st);
        
        char timestamp[100];
        sprintf_s(timestamp, "[%04d-%02d-%02d %02d:%02d:%02d]", 
                  st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
        
        logFile << timestamp << " " << message << std::endl;
        logFile.close();
    }
}
