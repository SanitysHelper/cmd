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
Press `C` and Enter to continue.

### 4. Execute Your Code
After the boot menu, you'll see:
```
[R] Run the code
[V] View the code
[E] Edit the code
[Q] Quit
```

- **[R]** - Execute the clipboard code
- **[V]** - View the exact code that will run
- **[E]** - Edit the code before running
- **[Q]** - Quit the program

### 5. Check Results
The program will:
1. Auto-detect the programming language
2. Execute the code
3. Display output or errors
4. Ask if you want to restart

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

*Optional languages require interpreters to be installed. See DEPENDENCIES.md

## Command-Line Usage

### Run from Terminal
```batch
# Interactive mode (with boot menu)
.\run.bat

# Execute code directly (skips boot menu)
.\run.bat "print('Hello World')"

# Clean workspace
.\run.bat /W
or
.\run.bat /WIPE
```

### Automated Scripts
```batch
# For testing: use /W to skip interactive prompts
@echo off
.\run.bat /W
echo %ERRORLEVEL%
if %ERRORLEVEL% equ 0 (
    echo Success!
) else (
    echo Failed!
)
```

## Configuration

### settings.ini Options

Edit `settings.ini` in the executor directory:

```ini
# Debug mode - shows detailed information (0=off, 1=on)
DEBUG=1

# Timeout in seconds (0=no limit, 60=60 seconds)
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

#### input.log
Records all user inputs in interactive mode:
```
[2025-12-05 13:45:23] User selected: R
[2025-12-05 13:45:25] Code executed successfully
```

#### important.log
Critical events and errors:
```
[INFO] Starting execution...
[SUCCESS] Code ran without errors
[ERROR] Missing interpreter: ruby
```

#### terminal.log
Full program output (if enabled in settings):
```
[BOOT] Script starting...
[INFO] Detecting language...
[DEBUG] Detected extension: .py
```

### View Logs
```batch
# Windows PowerShell
Get-Content "run_space\log\important.log"

# Command Prompt
type run_space\log\important.log
```

## Troubleshooting

### Problem: "Code not executing"

**Solution:**
1. Copy code again: Ctrl+C
2. Run program: `.\run.bat`
3. Select [V] to view code
4. Check if code appears correctly
5. If not, the clipboard may be empty

**Debug:**
- Enable DEBUG=1 in settings.ini
- Run again and review output
- Check logs in run_space/log/

### Problem: "Language not detected"

**Solution:**
1. Verify file extension is correct (.py, .ps1, .bat, etc.)
2. Enable DEBUG=1 in settings.ini
3. Review the "Detected extension:" line in output
4. Check if language is in LANGUAGES setting

**Example debug output:**
```
[DEBUG] Starting language detection...
[DEBUG] Checking Python patterns...
[DEBUG] Checking PowerShell patterns...
[DEBUG] Detected extension: .py
```

### Problem: "Interpreter not found"

**Solution:**
1. For Python: Install from python.org
2. For Node.js: Install from nodejs.org
3. Add to PATH: setx PATH "%PATH%;C:\path\to\interpreter"
4. Restart terminal and try again

**Verify installation:**
```batch
python --version
node --version
ruby --version
```

### Problem: "Access Denied" errors

**Possible causes:**
- Files are read-only
- Antivirus is blocking execution
- Insufficient permissions

**Solutions:**
1. Run as Administrator: Right-click run.bat → Run as administrator
2. Check file permissions: Right-click → Properties → Security
3. Add to antivirus whitelist if applicable

### Problem: "Workspace cleanup issues"

**Solution:**
```batch
# Manual cleanup - press [W] at boot menu
# Or run:
.\run.bat /W

# If cleanup fails:
# Delete manually:
rmdir /s /q run_space
mkdir run_space
```

## Advanced Usage

### Using with Other Tools

#### Batch File Wrapper
```batch
@echo off
REM Execute code from a file
setlocal enabledelayedexpansion
set "code=print('Hello from wrapper')"
echo !code! | clip
cd /d "%~dp0updatingExecutor"
.\run.bat
```

#### PowerShell Integration
```powershell
# Execute directly from PowerShell
$code = @'
print("Hello from PowerShell")
'@
$code | Set-Clipboard
& "C:\path\to\updatingExecutor\run.bat"
```

### Creating Custom Language Support

To add support for a new language:

1. Install the interpreter
2. Edit settings.ini - add language to LANGUAGES setting
3. The executor will auto-detect code patterns

Example for Go (.go):
```ini
LANGUAGES=python,powershell,batch,go
```

### Performance Optimization

For faster execution:

1. **Disable debug mode**: DEBUG=0 in settings.ini
2. **Reduce log level**: LOGLEVEL=1 (minimal)
3. **Disable performance monitoring**: PERFMON=0
4. **Set timeout**: TIMEOUT=30 (limits execution)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Ctrl+C | Copy to clipboard (Windows) |
| Ctrl+V | Paste from clipboard (Windows) |
| Enter | Confirm selection |
| Ctrl+C | Exit program (during execution) |

## File Structure

```
updatingExecutor/
├── run.bat                 - Main executable
├── settings.ini            - Configuration
├── DEPENDENCIES.md         - Dependency list
├── USER_GUIDE.md           - This file
├── backups/                - Version history
│   ├── run_v1.0.bat
│   ├── run_v1.1.bat
│   ├── run_v1.2.bat
│   └── run_v1.3.bat
└── run_space/              - Execution environment
    ├── README.md           - Program overview
    ├── log/                - Log files
    │   ├── input.log
    │   ├── important.log
    │   └── terminal.log
    ├── languages/          - Code files organized by language
    ├── clip_input.txt      - Current clipboard content
    └── [execution helpers] - Auto-generated scripts
```

## FAQs

**Q: Where is my original clipboard content?**
A: It's stored in `run_space/clip_input.txt` before execution.

**Q: Can I edit code after viewing?**
A: Yes! Press [E] to edit before running.

**Q: What happens if code crashes?**
A: The program catches errors and displays them. You can review in logs.

**Q: How do I save code for later?**
A: Copy code from [V] View option or check `run_space/languages/` directory.

**Q: Can I run multiple instances?**
A: Not recommended - they share the same `run_space/` directory.

**Q: How do I uninstall?**
A: Simply delete the `updatingExecutor/` folder.

## Getting Help

1. **Check logs**: `run_space/log/important.log`
2. **Enable debug**: Set DEBUG=1 in settings.ini
3. **Verify dependencies**: See DEPENDENCIES.md
4. **Review settings**: Check settings.ini for configuration

## Version Information

Current version: 1.3

Changes in this version:
- Added comprehensive settings system
- Implemented multi-level logging
- Enhanced language detection
- Added timeout support
- Improved error messages
- Auto-generated README

---

**Last Updated**: December 5, 2025

For more information, check the README.md in run_space/ directory.
