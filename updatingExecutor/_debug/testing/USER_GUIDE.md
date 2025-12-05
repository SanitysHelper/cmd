# Updating Executor - User Guide

## Quick Start

### 1. Copy Code to Clipboard
Select any code and press `Ctrl+C` to copy it to clipboard.

### 2. Run the Program
```batch
cd C:\Users\%USERNAME%\OneDrive\Desktop\cmd\updatingExecutor
run.bat
```

### 3. Choose Action at Boot Menu
```
[C] Continue normally (default)
[W] Wipe entire run_space directory and exit
```
Press the key or wait 5 seconds for automatic default selection ([C]).

### 4. Execute Your Code
After the boot menu, you'll see:
```
[R] Run the code (default)
[V] View the code
[E] Edit the code
[D] Detect file type
[Q] Quit
```

- **[R]** - Execute the clipboard code (auto-runs after 3 seconds)
- **[V]** - View the exact code that will run
- **[E]** - Edit the code before running
- **[D]** - Detect language from code
- **[Q]** - Quit the program

### 5. Check Results
The program will:
1. Auto-detect the programming language
2. Execute the code
3. Display output or errors
4. Ask if you want to run another code

## Supported Languages

| Language | Extension | Status | Example |
|----------|-----------|--------|---------|
| Python | `.py` | ✅ Built-in | `print("Hello")` |
| PowerShell | `.ps1` | ✅ Built-in | `Write-Host "Hello"` |
| Batch | `.bat` | ✅ Built-in | `echo Hello` |
| JavaScript | `.js` | 📦 Optional* | `console.log("Hello")` |
| Ruby | `.rb` | 📦 Optional* | `puts "Hello"` |
| Lua | `.lua` | 📦 Optional* | `print("Hello")` |
| Bash/Shell | `.sh` | 📦 Optional* | `echo "Hello"` |
| C/C++ | `.c/.cpp` | 📦 Optional* | Compilation not supported |

*Optional languages require interpreters to be installed. See DEPENDENCIES.md

## Command-Line Usage

### Run from Terminal
```batch
REM Interactive mode (with boot menu)
.\run.bat

REM Clean workspace
.\run.bat /W
or
.\run.bat /WIPE
```

### Automated Scripts
```batch
@echo off
cd C:\Path\To\updatingExecutor
.\run.bat /W
if %ERRORLEVEL% equ 0 (
    echo Success!
) else (
    echo Failed!
)
```

## Configuration

Edit `settings.ini` to customize behavior:

```ini
# Debug mode - shows detailed information (0=off, 1=on)
DEBUG=1

# Timeout in seconds (0=no limit)
TIMEOUT=0

# Log verbosity (1=minimal, 2=normal, 3=verbose)
LOGLEVEL=2

# Auto-cleanup temp files (0=off, 1=on)
AUTOCLEAN=1

# Stop on first error (0=continue, 1=stop)
HALTONERROR=0

# Enable performance monitoring (0=off, 1=on)
PERFMON=0

# Number of retries for failed operations
RETRIES=3

# Comma-separated list of enabled languages
LANGUAGES=python,powershell,batch

# Output directory (blank=use run_space)
OUTPUT=

# Backup on wipe operation (0=off, 1=on)
BACKUP=1
```

## Logging

### Log Files Location
All logs are stored in: `run_space/log/`

### Log Types

#### important.log
Critical events and execution results with timestamps:
```
[EXECUTION] Success - File: clipboard_code.py - 2025-12-05 01:42 PM
```

#### input.log
All user inputs in interactive mode (if logging enabled)

#### terminal.log
Full program output (if verbose logging enabled with LOGLEVEL=3)

### View Logs
```batch
REM Windows PowerShell
Get-Content "run_space\log\important.log"

REM Command Prompt
type run_space\log\important.log
```

## Troubleshooting

### Program Hangs
**Solution**: All menus auto-timeout after 3-5 seconds with default selection

### Code not executing?
1. Verify code is in clipboard: Ctrl+C to copy
2. Run program: `.\run.bat`
3. Check language detection: Enable DEBUG=1 in settings.ini
4. Review logs in run_space/log/important.log

### Syntax errors in code?
1. Select [V] View to see exact code being executed
2. Fix code and copy again to clipboard
3. Re-run executor

### Workspace needs cleanup?
1. Run: `.\run.bat /W`
2. Or press [W] at boot menu
3. All files deleted except settings, documentation, and backups

## File Structure

```
updatingExecutor/
├── run.bat                   Main executor (self-contained)
├── settings.ini              Configuration (auto-created)
├── USER_GUIDE.md             This file
├── DEPENDENCIES.md           Interpreter setup guide
├── COMPLIANCE_REPORT.md      40+ requirements tracking
├── PROJECT_STATUS.md         Deployment status
├── TEST_REPORT.md            Test results
├── backups/                  Version history
│   ├── run_v1.0.bat
│   ├── run_v1.1.bat
│   ├── run_v1.2.bat
│   ├── run_v1.3.bat
│   ├── run_v1.4.bat
│   ├── run_v1.5.bat
│   └── run_v1.6.bat
└── run_space/                Isolated execution directory
    ├── log/                  Log files
    │   ├── important.log     Execution records
    │   ├── input.log         User inputs
    │   └── terminal.log      Program output
    ├── languages/            Code organized by language
    ├── README.md             Auto-generated
    ├── read_clipboard.ps1    PowerShell helper
    ├── strip_bom.bat         BOM stripper
    ├── execute_code.bat      Universal executor
    └── clipboard_code.*      Generated code files

updatingExecutor_testenv/    Isolated test environment (copy of full directory)
```

## Advanced Usage

### Debug Mode
```batch
REM Edit settings.ini and set:
DEBUG=1

REM Run again - you'll see [DEBUG] messages throughout execution
.\run.bat
```

### Custom Output Directory
```batch
REM Edit settings.ini and set:
OUTPUT=C:\MyOutputFolder

REM Run:
.\run.bat
```

### Verbose Logging
```batch
REM Edit settings.ini and set:
LOGLEVEL=3

REM Run:
.\run.bat
```

## Performance Tips

1. **Faster startup**: Set DEBUG=0 in settings.ini
2. **Faster execution**: Use Python instead of PowerShell when possible
3. **Batch operations**: Use command-line argument instead of interactive menu

## FAQ

**Q: Where is my original clipboard content?**  
A: Stored in `run_space/clip_input.txt` before execution.

**Q: Can I edit code after viewing?**  
A: Yes! Press [E] at the menu to edit before running.

**Q: What happens if code crashes?**  
A: The program catches errors and displays them. Check logs for details.

**Q: How do I save code for later?**  
A: Copy from [V] View option or check run_space/languages/ for saved files.

**Q: Can I run multiple instances?**  
A: Not recommended - they share the same run_space directory.

**Q: How do I uninstall?**  
A: Simply delete the updatingExecutor/ folder.

**Q: Can I run code from a file instead of clipboard?**  
A: Edit run.bat to accept file path argument (future enhancement).

**Q: What's the difference between /W and manual wipe?**  
A: Both do the same thing - delete temporary files while preserving configuration.

**Q: Can I use this on other Windows versions?**  
A: Yes! Tested on Windows 10+ with PowerShell 5.0+.

## Getting Help

1. **Check logs**: `run_space/log/important.log`
2. **Enable debug**: Set DEBUG=1 in settings.ini
3. **Review DEPENDENCIES.md**: For interpreter setup issues
4. **Check USER_GUIDE.md**: You're reading it!

---

**Version**: 1.6  
**Last Updated**: December 5, 2025  
**Status**: Production Ready ✅
