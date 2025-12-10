# _DEBUG Implementation - Quick Reference

## 📋 Overview

All programs in the cmd workspace now use a standardized `_debug` directory structure to store backups and testing environments in a location that is **never deleted by the `/W` wipe command**.

## 🎯 What Changed

### Before
```
program/
├── run.bat
├── backups/  ← Stored at root level
│   ├── run_v1.0.bat
│   └── ...
└── run_space/  ← Deleted on wipe
```

### After
```
program/
├── run.bat
├── _debug/  ← Protected from wipe
│   └── backups/
│       ├── run_v1.0.bat
│       └── ...
└── run_space/  ← Deleted on wipe
```

## ✅ Status by Program

| Program | Status | Details |
|---------|--------|---------|
| **updatingExecutor** | ✅ Complete | 7 backups in `_debug/backups/`, testing in `_debug/testing/` |
| **tagScanner** | ✅ Ready | Backup move logic added, activates on first run |
| **killprocess** | ✅ Ready | Backup move logic added, activates on first run |
| **codeFetcher** | ✅ Ready | Backup move logic added, activates on first run |
| **dirWatcher** | ✅ Ready | Backup move logic added, activates on first run |
| **executeforMusic** | ⏳ Future | Structure ready for future use |

## 🛡️ Wipe Command (`/W`) Behavior

**What Gets Deleted**:
- `run_space/` directory
- Temp files and generated scripts

**What Gets Preserved**:
- `run.bat` (main executable)
- `*.ini` (configuration files)
- `*.md` (documentation)
- **`_debug/` (ENTIRE DIRECTORY - untouched)**

## 🔄 How Backup Migration Works

When a program runs for the first time after update:

1. **Check**: Does `_debug/backups/` already exist?
   - Yes → Skip (idempotent)
   - No → Continue

2. **Create**: Make `_debug/` and `_debug/backups/` directories

3. **Migrate**: Copy all files from `backups/` to `_debug/backups/`

4. **Cleanup**: Delete original `backups/` folder

5. **Continue**: Program runs normally

**Result**: Automatic, silent, runs only once

## 📂 Directory Structure Pattern

```
program/
│
├── run.bat (launcher/executor)
├── settings.ini (configuration)
├── *.md (documentation)
├── *.txt (data files)
│
├── _debug/ ⭐ (NEVER DELETED BY /W)
│   ├── backups/
│   │   ├── run_v1.0.bat
│   │   ├── run_v1.1.bat
│   │   └── ... (version history)
│   │
│   └── testing/ (for programs with extensive tests)
│       ├── run.bat
│       ├── runBackup[vX.X].bat
│       ├── runBackup[vX.X].ps1
│       └── run_space/
│
└── run_space/ (DELETED BY /W)
    ├── log/
    ├── languages/
    └── ... (temp files)
```

## 🚀 Usage Examples

### View Backups
```powershell
# updatingExecutor backups
Get-ChildItem "C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\backups"

# Output:
# run_v1.0.bat
# run_v1.1.bat
# run_v1.2.bat
# ... (7 versions total)
```

### Run Test Environment
```batch
cd C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\testing
.\run.bat
```

### Run Tests
```batch
cd C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\testing
.\runBackup[v1.6].bat
```

```powershell
cd C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\testing
.\runBackup[v1.6].ps1
```

### Wipe Program (Preserves _debug)
```batch
cd C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor
run.bat /W
```

Output:
```
[INFO] Wiping workspace directory: C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\
[INFO] Preserving: run.bat, _debug/, run_space/, *.ini, *.md
[OK] run_space deleted.
[INFO] Workspace cleaned. Preserved: run.bat, _debug/, run_space/
```

## 📍 Key Locations

### updatingExecutor
- **Backups**: `C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\backups\`
- **Testing**: `C:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor\_debug\testing\`
- **Test Runners**: 
  - `runBackup[v1.6].bat` (batch-based)
  - `runBackup[v1.6].ps1` (PowerShell-based)

### Other Programs
- Backup move logic added, will create `_debug/` on first run
- No backups currently stored (will be added as programs are updated)

## 📚 Documentation Files

1. **_DEBUG_STRUCTURE_SUMMARY.md**
   - Comprehensive technical reference
   - Implementation details for all programs
   - Future enhancement suggestions
   - File modification list

2. **IMPLEMENTATION_COMPLETE.md**
   - Detailed completion report
   - Testing results
   - Verification checklist
   - What changed summary

3. **This File**
   - Quick reference guide
   - Status overview
   - Usage examples
   - Key locations

## ⚙️ Technical Details

### Backup Move Code (Added to All Programs)

```batch
rem === Move any backups to _debug directory on first run ===
set "DEBUG_DIR=%SCRIPT_DIR%_debug"
set "DEBUG_BACKUPS=%DEBUG_DIR%\backups"

if not exist "%DEBUG_DIR%" mkdir "%DEBUG_DIR%"

if exist "%SCRIPT_DIR%backups" (
    if not exist "%DEBUG_BACKUPS%" (
        mkdir "%DEBUG_BACKUPS%" 2>nul
        xcopy "%SCRIPT_DIR%backups\*" "%DEBUG_BACKUPS%\" /E /Y >nul 2>&1
        rmdir /s /q "%SCRIPT_DIR%backups" >nul 2>&1
    )
)
```

### Wipe Protection Code (Updated in run.bat)

```batch
rem Delete all subdirectories except _debug and run_space
set "DIR_COUNT=0"
for /d %%D in (*) do (
    if not "%%D"=="_debug" if not "%%D"=="run_space" (
        rmdir /s /q "%%D" >nul 2>&1
        set /a "DIR_COUNT+=1"
        if "%DEBUG%"=="1" echo [OK] %%D deleted.
    )
)
```

## 🎓 For Future Programs

When creating a new program in the cmd workspace:

1. **Include backup move logic** from the start (see code above)
2. **Create `_debug/`** directory on first run
3. **Store backups** in `_debug/backups/`
4. **Update wipe logic** to preserve `_debug/`
5. **Document structure** in program README
6. **Add testing** in `_debug/testing/` if applicable

---

**Last Updated**: December 5, 2025  
**Status**: ✅ Production Ready  
**Version**: 1.0
