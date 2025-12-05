# Updating Executor - Code Executor Tool

## Overview
This is a clipboard-based code executor that automatically detects programming language,
executes the code, and provides clear feedback on success or failure.

## Supported Languages
- Python (.py)
- PowerShell (.ps1)
- Batch (.bat)
- JavaScript (.js)
- Ruby (.rb)
- Lua (.lua)
- Shell (.sh)

## Features
- Automatic language detection based on code patterns
- Isolated execution environment in run_space/
- Comprehensive logging in run_space/log/
- Configurable behavior via settings.ini
- Debug mode for troubleshooting
- Automatic file cleanup on exit

## Project Structure
```
run.bat                    - Main executor (single-file, self-contained)
settings.ini               - Configuration file
backups/                   - Version history
run_space/                 - Isolated execution directory
├── log/                   - Log files
│   ├── input.log          - User input history
│   ├── important.log      - Critical events
│   └── terminal.log       - Program output
├── languages/             - Code files organized by language
├── clip_input.txt         - Clipboard content
└── README.md              - This file
```

## Usage

### Interactive Mode
1. Copy code to clipboard
2. Run: `.\run.bat`
3. Press [C] to continue or [W] to wipe workspace
4. Select action: [R] Run, [V] View, [E] Edit, or [Q] Quit

### Command-Line Mode
- `.\run.bat /W`       - Clean workspace
- `.\run.bat /WIPE`    - Same as /W
- `.\run.bat code`     - Execute code directly

### Automated Testing
When running tests, /W flag is recognized automatically to skip boot menu.

## Configuration
Edit `settings.ini` to customize:
- DEBUG: Enable debug output (0/1)
- TIMEOUT: Execution timeout in seconds (0=disabled)
- LOGLEVEL: Verbosity (1=minimal, 2=normal, 3=verbose)
- AUTOCLEAN: Auto-cleanup temp files (0/1)
- HALTONERROR: Stop on first error (0/1)
- PERFMON: Performance monitoring (0/1)
- RETRIES: Retry count for failed operations
- LANGUAGES: Supported language list

## Logging
- **input.log**: All user inputs (interactive mode)
- **important.log**: Critical events, errors, execution results
- **terminal.log**: Full program output (if enabled)

## Exit Codes
- 0: Success
- 1: Failure
- 2: Missing dependency

## Troubleshooting

### Code not executing?
1. Verify code is in clipboard: Ctrl+C to copy
2. Check language detection: Enable DEBUG=1 in settings.ini
3. Review logs in run_space/log/

### Syntax errors in code?
1. Run with [V] View to see exact code being executed
2. Fix code and copy again to clipboard
3. Re-run executor

### Workspace cleanup?
1. Press [W] at boot menu to wipe all files except run.bat
2. Or run: `.\run.bat /W`

## Version
1.0=1.3

Generated automatically on first run.
