# termUI Installer

**Automated installer for termUI - Downloads and installs termUI from GitHub**

## Overview

termUIInstaller is a C++ application that automates the installation of termUI by downloading it directly from the GitHub repository and installing it to your chosen location.

## Features

- **Automated Download**: Downloads termUI from GitHub (SanitysHelper/cmd repository)
- **Multiple Installation Locations**: Choose from current directory, Program Files, Documents, or custom path
- **Progress Tracking**: Shows download progress and installation status
- **Automatic Extraction**: Extracts and copies files using PowerShell and robocopy
- **Logging**: All operations logged to `_debug/logs/installer.log`
- **Clean Installation**: Automatically cleans up temporary files after installation

## Requirements

- Windows 10/11
- Internet connection
- C++ compiler (for building from source):
  - Visual Studio with C++ Build Tools, OR
  - MinGW-w64
- PowerShell (for extraction)

## Usage

### Quick Start

1. **Double-click** `run.bat` or run from command line:
   ```batch
   run.bat
   ```

2. The installer will:
   - Auto-compile if executable doesn't exist
   - Download termUI from GitHub
   - Show download progress
   - Prompt for installation confirmation
   - Ask for installation location
   - Install termUI files
   - Clean up temporary files

3. Follow the on-screen prompts:
   - Confirm installation (Y/N)
   - Select installation location (1-4)
   - Wait for completion

### Installation Locations

| Option | Location | Description |
|--------|----------|-------------|
| 1 | Current directory | Installs in `./termUI` |
| 2 | Program Files | `C:\Program Files\termUI\termUI` |
| 3 | Documents | `%USERPROFILE%\Documents\termUI\termUI` |
| 4 | Custom | User-specified path |

### Manual Compilation

If you want to compile manually:

```batch
compile.bat
```

The executable will be created at: `bin\termUIInstaller.exe`

## File Structure

```
termUIInstaller/
├── run.bat                          # Main launcher
├── compile.bat                      # Compilation script
├── termUIInstaller.cpp              # C++ source code
├── README.md                        # This file
├── bin/
│   └── termUIInstaller.exe         # Compiled executable
└── _debug/
    ├── logs/
    │   └── installer.log           # Installation log
    └── automated_testing_environment/
```

## How It Works

1. **Download Phase**:
   - Uses WinINet API to download from GitHub
   - Downloads `https://github.com/SanitysHelper/cmd/archive/refs/heads/main.zip`
   - Shows progress in real-time

2. **Extraction Phase**:
   - Uses PowerShell's `Expand-Archive` cmdlet
   - Extracts to temporary directory

3. **Installation Phase**:
   - Prompts user for confirmation
   - Asks for installation location
   - Uses `robocopy` to copy `termUI` folder
   - Creates necessary directories

4. **Cleanup Phase**:
   - Deletes downloaded ZIP file
   - Removes temporary extraction directory

## Logging

All operations are logged to `_debug/logs/installer.log` with timestamps:

```
[2025-12-08 12:34:56] termUI Installer started
[2025-12-08 12:34:56] Attempting to download from: https://github.com/...
[2025-12-08 12:35:02] Downloaded 1234567 bytes
[2025-12-08 12:35:02] Extraction successful
[2025-12-08 12:35:05] User prompt: Do you want to install termUI? - Response: Y
[2025-12-08 12:35:08] Installation path: C:\Users\...\Documents\termUI
[2025-12-08 12:35:12] Installation successful
```

## Compilation Options

### Using Visual Studio (MSVC)

```batch
REM From Developer Command Prompt for VS
compile.bat
```

### Using MinGW

```batch
REM Ensure g++.exe is in PATH
compile.bat
```

### Manual Compilation Commands

**MSVC**:
```cmd
cl.exe /EHsc /O2 /Fe:bin\termUIInstaller.exe termUIInstaller.cpp wininet.lib shell32.lib
```

**MinGW**:
```cmd
g++ -std=c++11 -O2 -o bin\termUIInstaller.exe termUIInstaller.cpp -lwininet -lole32 -static-libgcc -static-libstdc++
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success or user cancelled |
| 1 | Download failed |
| 1 | Extraction failed |
| 1 | Copy failed |

## Troubleshooting

### Compilation Errors

**Error**: "No C++ compiler found"
- **Solution**: Install Visual Studio with C++ Build Tools or MinGW-w64
- **MSVC**: Run from "Developer Command Prompt for VS"

### Download Errors

**Error**: "Failed to download termUI from GitHub"
- **Solution**: Check internet connection
- **Solution**: Verify GitHub repository is accessible
- **Solution**: Check firewall/proxy settings

### Extraction Errors

**Error**: "Failed to extract archive"
- **Solution**: Ensure PowerShell is available
- **Solution**: Check disk space
- **Solution**: Verify ZIP file isn't corrupted

### Installation Errors

**Error**: "Failed to copy files"
- **Solution**: Check write permissions for installation path
- **Solution**: Run as Administrator for Program Files installation
- **Solution**: Ensure robocopy is available (built into Windows)

## GitHub Repository

- **Repo**: https://github.com/SanitysHelper/cmd
- **Branch**: main
- **Folder**: termUI

## Version

**termUI Installer v1.0.0** - Created December 2025

## Notes

- Requires internet connection for download
- PowerShell used for ZIP extraction (built into Windows 10/11)
- Robocopy used for file copying (built into Windows)
- Temporary files stored in current directory during installation
- All logs stored in `_debug/logs/installer.log`

## Running termUI After Installation

After successful installation, navigate to the installation directory and run:

```batch
cd "C:\path\to\installation\termUI"
.\run.bat
```

The installer displays the exact commands at completion.
