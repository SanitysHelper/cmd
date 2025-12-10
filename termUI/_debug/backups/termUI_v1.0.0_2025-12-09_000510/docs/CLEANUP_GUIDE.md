# termUI Cleanup - Organization Guide

### What Was Cleaned Up

The termUI directory has been reorganized to separate core functionality from utility, development, and debugging files.

### Files Moved to `_bin/` Folder

The following non-essential files and folders were moved to keep the root directory clean:

```
_bin/
├── _debug/                    # Debugging logs and testing environment
│   ├── logs/                  # All program logs
│   └── automated_testing_environment/
├── csharp/                    # C# InputHandler (development/experimental)
│   ├── bin/                   # Compiled binaries
│   ├── InputHandler.cs        # C# keyboard handler
│   ├── KeyboardBridge.cs      # Keyboard bridge
│   └── compile_inputhandler.bat
├── python/                    # (empty, reserved for future)
├── GitHub-VersionCheck.ps1    # GitHub version checking utility
└── VERSION_UPDATER.ps1        # Version update utility
```

### Directories Removed

Empty temporary directories were deleted:
- `powershell/_runspace/` - Empty runtime folder
- `_runspace/` - Empty runtime folder

## Current Clean Structure

```
termUI/
├── _bin/                      # Utilities & development (archived)
│   ├── _debug/                # Debugging & testing
│   ├── csharp/
│   ├── python/
│   ├── GitHub-VersionCheck.ps1
│   └── VERSION_UPDATER.ps1
├── buttons/                   # Menu button definitions
├── docs/                      # Documentation
├── powershell/                # Core PowerShell modules
│   ├── modules/
│   └── termUI.ps1
├── run.bat                    # Main executable
├── settings.ini               # Configuration
├── VERSION.json               # Version tracking
└── README.md                  # Program README
```

## What This Means

### Core System (in root)
- **run.bat** - Entry point (required)
- **settings.ini** - Configuration (required)
- **VERSION.json** - Version tracking (required)
- **powershell/** - Core functionality (required)
- **buttons/** - Menu definitions (required)
- **docs/** - Documentation (helpful)
- **_debug/** - Debugging tools (helpful)

### Development/Utility (in _bin/)
- **csharp/** - Not actively used in current system
- **GitHub-VersionCheck.ps1** - Optional utility for version checking
- **VERSION_UPDATER.ps1** - Optional utility for updating versions
- **python/** - Reserved for future expansion

## Why This Cleanup?

✅ **Cleaner interface** - Root only shows active files
✅ **Clear purpose** - Obvious what's core vs. utility
✅ **Easier navigation** - Less clutter when opening folder
✅ **Better organization** - Related utilities grouped in _bin/
✅ **Maintained compatibility** - All functionality still works

## If You Need a File from _bin/

Simply copy it out:

```powershell
# Access GitHub version checker
Copy-Item "_bin/GitHub-VersionCheck.ps1" .

# Access version updater
Copy-Item "_bin/VERSION_UPDATER.ps1" .
```

Or reference it directly in scripts:

```powershell
. "_bin/GitHub-VersionCheck.ps1"
. "_bin/VERSION_UPDATER.ps1"
```

## All Copies Synchronized

The cleanup was applied to all three termUI instances:
- ✅ termUI/
- ✅ termCalc/termUI/
- ✅ cmdBrowser/termUI/

All have identical clean structure.

## Status

**Cleanup Complete** ✓
**Structure**: Clean and organized
**Functionality**: Unchanged
**Date**: 2025-12-08
