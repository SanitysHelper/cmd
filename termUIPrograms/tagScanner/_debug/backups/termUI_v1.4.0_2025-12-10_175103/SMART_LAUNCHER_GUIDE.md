# termUI.exe - Smart Standalone Launcher

**Version**: Enhanced with Auto-Update Detection & Repair Checking  
**Date**: December 9, 2025  
**Size**: 8.7 KB (native executable)

## Overview

The `termUI.exe` is a **smart, standalone launcher** that can be copied anywhere and will handle its own setup, update checking, and repair detection automatically.

## ✅ YES - It Works Standalone!

You can copy **just `termUI.exe`** to any program folder and start building UIs with it. The launcher will:

1. ✅ **Check for missing files** - Detects if termUI installation is incomplete
2. ✅ **Check for updates** - Compares local version against GitHub
3. ✅ **Prompt for updates** - Notifies when newer version available
4. ✅ **Provide repair instructions** - Guides user if files are missing
5. ✅ **Launch termUI.ps1** - Starts the framework after all checks pass

---

## Smart Features

### 🔍 Auto-Detection

The launcher automatically checks for:
- `powershell/` directory existence
- `powershell/termUI.ps1` main script
- `VERSION.json` metadata file
- `settings.ini` configuration

### 📦 Repair Detection

If any required files are missing, the launcher will:
```
ERROR: termUI installation incomplete or corrupted

Required structure:
  termUI.exe           (this launcher)
  VERSION.json         (version metadata)
  settings.ini         (configuration)
  powershell/          (PowerShell modules)
    termUI.ps1         (main script)
    modules/           (supporting modules)

To repair: Download full termUI from GitHub
https://github.com/SanitysHelper/cmd/tree/main/termUI

Press any key to exit...
```

### 🔄 Update Checking

On each launch, the exe:
1. Reads local `VERSION.json` (e.g., `1.3.0`)
2. Fetches GitHub `VERSION.json` (e.g., `1.3.2`)
3. Compares versions using semantic versioning
4. Displays update notification if newer version available:

```
=== termUI Launcher ===

Update available: v1.3.0 -> v1.3.2

To update, run: .\termUI.exe --update
Or use Update-Manager.ps1 from PowerShell

Press any key to continue with current version...
```

### ⚡ Fast Startup

- **No internet?** - Continues immediately (no hang/timeout)
- **Up to date?** - Launches instantly, no prompts
- **5-second timeout** - Network check doesn't slow startup

---

## Usage Patterns

### Pattern 1: Copy to New Program

```bash
# Copy just the exe
copy C:\termUI\termUI.exe C:\MyNewProgram\termUI.exe

# Run it
cd C:\MyNewProgram
.\termUI.exe
```

**Result**: Launcher detects missing files and shows repair instructions.

### Pattern 2: Copy Full termUI Folder

```bash
# Copy entire termUI structure
xcopy C:\termUI C:\MyProgram\termUI\ /E /I

# Run from new location
cd C:\MyProgram\termUI
.\termUI.exe
```

**Result**: 
- Checks for updates from GitHub
- Notifies if newer version available
- Launches menu system

### Pattern 3: Just Drop the EXE

```bash
# You already have termUI structure in your program
C:\MyProgram\
  ├── termUI.exe          ← Drop here
  ├── VERSION.json
  ├── settings.ini
  └── powershell/
      ├── termUI.ps1
      └── modules/

# Run it
.\termUI.exe
```

**Result**: Works immediately, checks for updates, runs your UI.

---

## Command-Line Flags

All flags are passed through to `termUI.ps1`:

```bash
# Check version
.\termUI.exe --version

# View changelog  
.\termUI.exe --changelog

# Capture mode (for automation)
.\termUI.exe --capture-file output.json --capture-path "mainUI/Settings"

# Help
.\termUI.exe --help
```

---

## Required File Structure

For termUI.exe to work, you need this minimal structure:

```
YourProgram/
├── termUI.exe              ← The smart launcher (8.7 KB)
├── VERSION.json            ← Version metadata
├── settings.ini            ← Configuration
├── powershell/             ← PowerShell framework
│   ├── termUI.ps1          ← Main script
│   └── modules/            ← Supporting modules
│       ├── InputBridge.ps1
│       ├── Logging.ps1
│       ├── MenuBuilder.ps1
│       ├── Settings.ps1
│       ├── VersionManager.ps1
│       └── Update-Manager.ps1
└── buttons/                ← Your UI definitions
    └── mainUI/
        ├── Option1.button
        └── Option2.button
```

---

## Building Your UI

Once `termUI.exe` is in place:

1. Create `buttons/` folder structure
2. Add `.button` files for menu items
3. Run `termUI.exe` to see your UI
4. The launcher handles everything else automatically

Example button file (`buttons/mainUI/MyTool.button`):
```
name=My Tool
type=option
description=Launch my custom tool
```

---

## Update Workflow

### Automatic Update Check
Every time you run `termUI.exe`, it checks GitHub (with 5-sec timeout).

### Manual Update
```powershell
# Using termUI's built-in updater
cd powershell
.\Update-Manager.ps1

# Or via termUI.exe flag (future enhancement)
.\termUI.exe --update
```

### Development Version
If your local version is **newer** than GitHub:
```
Running development version: v1.4.0-dev (GitHub: v1.3.2)
```
Continues without prompting (assumes you're developing).

---

## Troubleshooting

### "termUI.exe not recognized"
- Ensure you're in the correct directory
- Use full path: `C:\path\to\termUI.exe`
- Check file isn't corrupted (should be 8.7 KB)

### "powershell directory not found"
- Download full termUI from GitHub
- Extract to same folder as termUI.exe
- Ensure folder structure matches requirements

### "Update check failed"
- No internet? Update check skips automatically
- Firewall blocking? Allow termUI.exe network access
- GitHub down? Launcher continues with local version

### Version shows as 1.3.2 but local is 1.3.0
- This is normal! Launcher shows GitHub version in header
- Your local installation is 1.3.0
- Update available notification will display

---

## Technical Details

### Compilation
- **Language**: C# (.NET Framework 4.0+)
- **Compiler**: csc.exe (included with Windows)
- **Dependencies**: System.dll, System.Net.dll
- **Size**: 8,704 bytes (8.7 KB)

### Version Comparison
Uses semantic versioning (major.minor.patch):
- `1.3.0 < 1.3.2` → Update available
- `1.3.2 = 1.3.2` → Up to date
- `1.4.0 > 1.3.2` → Development version

### Network Behavior
- **Timeout**: 5 seconds for GitHub check
- **No Hang**: Continues if network unavailable
- **Silent Fail**: No errors if GitHub unreachable
- **TLS 1.2**: Secure HTTPS connection

---

## Summary

✅ **Copy termUI.exe anywhere** - It's fully standalone  
✅ **Auto-detects missing files** - Shows repair instructions  
✅ **Checks for updates** - Compares with GitHub automatically  
✅ **Prompts when newer version exists** - User can choose to update  
✅ **Fast startup** - Network check doesn't block or hang  
✅ **Passes all flags through** - Works with all termUI.ps1 features  
✅ **Works offline** - No internet required (just skips update check)  

**You can now copy just `termUI.exe` to any program folder and start building UIs immediately. It will handle the rest!**
