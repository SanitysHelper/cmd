# v1.4 Quick Reference Guide

## What Changed

### 1. DEBUG Mode OFF by Default
```ini
DEBUG=0    # Changed from 1
```
Debug output is now OFF by default. Enable via Settings menu if needed.

---

### 2. Settings Menu (NEW)
Access at boot or main menu via **[S]**

**In Settings Menu**:
- [1] Debug Mode (0/1)
- [2] Auto Input (0/1)  
- [3] Wait Time (1-60 sec)
- [4] Enable Wipe (0/1)
- [5] Enable Previous Code (0/1)
- [6] Log Level (1-3)
- [B] Back
- [S] Save & Continue
- [Q] Quit

---

### 3. Boot Menu Updates
```
[C] Continue (default)
[S] Settings          ← NEW
[W] Wipe              ← Controlled by ENABLEWIPE setting
[Q] Quit              ← NEW
```

Wait time now uses **WAITTIME** setting (default 5 seconds, 3 when DEBUG=1)

---

### 4. Auto Input Toggle (NEW)
```ini
AUTOINPUT=1    # When 1: Timeout, when 0: Unlimited time
```

**When AUTOINPUT=1** (Enabled):
- Boot/main menu countdown for WAITTIME seconds
- Default selection if no input

**When AUTOINPUT=0** (Disabled):
- No timeout
- User has unlimited time to choose
- No countdown message

---

### 5. Wait Time Configuration (NEW)
```ini
WAITTIME=5    # Used for ALL timeouts
```

Set once, used everywhere (boot menu, main menu, etc.)
- Range: 1-60 seconds
- Auto-sets to 3 when DEBUG=1

---

### 6. Previous Code Feature (NEW)
```ini
ENABLEPREVIOUSCODE=1    # When 1: [P] option available
```

**How it works**:
1. Run code normally
2. If successful, auto-saved to `run_space/previous_code.txt`
3. At main menu, press [P] to re-execute

**Main Menu**:
```
[R] Run (from clipboard)
[V] View only
[E] Edit
[D] Detect
[P] Previous      ← NEW (if enabled and file exists)
[S] Settings      ← NEW
[Q] Quit
```

---

### 7. Wipe Option Configurable (NEW)
```ini
ENABLEWIPE=1    # When 0: [W] hidden, when 1: [W] visible
```

Hide or show wipe option at boot menu via settings.

---

## User Workflows

### Scenario 1: Need More Time to Choose?
1. At boot/main menu: Press [S]
2. Settings Menu → [2] Auto Input → Set to 0
3. Back to menu, now unlimited time to choose

### Scenario 2: Disable Wipe Option
1. At boot/main menu: Press [S]
2. Settings Menu → [4] Enable Wipe → Set to 0
3. [W] now hidden from boot menu

### Scenario 3: Change Timeout (2 seconds instead of 5)
1. At boot/main menu: Press [S]
2. Settings Menu → [3] Wait Time → Set to 2
3. All timeouts now 2 seconds

### Scenario 4: Rerun Last Code
1. At main menu: Press [P]
2. Last successfully executed code automatically runs
3. No need to copy from clipboard again

### Scenario 5: Enable Debug Mode
1. At boot/main menu: Press [S]
2. Settings Menu → [1] Debug Mode → Set to 1
3. Also auto-sets wait time to 3 seconds
4. Verbose output enabled

---

## Settings File

**Location**: `updatingExecutor/settings.ini`

**Edit Via**:
- Boot menu → [S] → Interactive menu
- Main menu → [S] → Interactive menu
- Manual text editor (requires restart)

**All Settings**:
```ini
DEBUG=0                    # 0=off, 1=on (verbose)
AUTOINPUT=1                # 0=unlimited time, 1=timeout
WAITTIME=5                 # Timeout seconds (1-60)
ENABLEWIPE=1               # 0=hide W, 1=show W
ENABLEPREVIOUSCODE=1       # 0=disable [P], 1=enable [P]
LOGLEVEL=2                 # 1=min, 2=normal, 3=verbose
TIMEOUT=0                  # Auto-exit (0=disabled)
AUTOCLEAN=1                # Auto cleanup (0/1)
HALTONERROR=0              # Stop on error (0/1)
PERFMON=0                  # Performance monitor (0/1)
RETRIES=3                  # Retry attempts
LANGUAGES=python,powershell,batch
OUTPUT=                    # Output dir
BACKUP=1                   # Backup on wipe (0/1)
```

---

## Key Points

✅ **Settings persist** between sessions  
✅ **Menu-driven editing** (no manual config needed)  
✅ **Dynamic timeouts** (change WAITTIME once, affects all)  
✅ **Smart defaults** (DEBUG=0, AUTOINPUT=1, ENABLEWIPE=1)  
✅ **Previous code** auto-saves, easy to rerun  
✅ **Input flexibility** (choose timed or unlimited)  
✅ **Backward compatible** (works with old settings)  

---

## Version Info

- **Previous**: v1.3 (boot menu, basic settings)
- **Current**: v1.4 (full settings management, previous code)
- **Status**: Production Ready ✅
- **Tested**: All features verified working

---

## Common Issues

**Q: [P] option not showing at main menu?**  
A: Either ENABLEPREVIOUSCODE=0, or no previous code has been executed yet.

**Q: Wait time not changing?**  
A: All timeouts use WAITTIME setting. Change it in Settings menu #3.

**Q: W option disappeared from boot menu?**  
A: ENABLEWIPE=0. Go to Settings → #4 to enable.

**Q: Debug mode auto-disabled when I set WAITTIME?**  
A: No, but DEBUG=1 auto-adjusts WAITTIME to 3 seconds on boot.

**Q: Can I delete previous_code.txt manually?**  
A: Yes, it will recreate after next successful run, or [P] will show error.

---

## Files Modified

| File | Changes |
|------|---------|
| `run.bat` | +250 lines, settings menu, previous code logic |
| `settings.ini` | 4 new settings, DEBUG=0 default |
| `waiter.ps1` | No changes |

---

## Documentation

- **CHANGELOG_v1.4.md** - Detailed version history
- **IMPLEMENTATION_SUMMARY_v1.4.md** - Technical details
- **This File** - Quick reference

---

**Version**: 1.4  
**Released**: December 5, 2025  
**Status**: ✅ Production Ready
