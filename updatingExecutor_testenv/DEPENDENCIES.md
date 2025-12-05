# Updating Executor - Dependencies

## Overview
This document lists all external dependencies required for the Updating Executor to function properly.

## System Requirements

### Windows
- **Minimum**: Windows 7 or later
- **Recommended**: Windows 10 or later
- **Architecture**: 64-bit recommended, 32-bit supported

### Required System Components
1. **Windows PowerShell**
   - Version: 5.0 or later (built-in on Windows 10+)
   - Used for: Clipboard interaction, system commands
   - Status: ✅ Pre-installed on all supported Windows versions

2. **Command Prompt (cmd.exe)**
   - Status: ✅ Pre-installed on all Windows systems

## Language Interpreters

### Core (Pre-installed)
- **Batch (cmd)** - ✅ Built-in
- **PowerShell** - ✅ Built-in (5.0+)

### Optional (Auto-detected)
The following interpreters are auto-detected if installed. If not found, code in those languages will not execute:

#### Python
- **Status**: Optional
- **Versions**: 3.6+
- **Detection**: Checks for `python` or `python3` in PATH
- **Installation**: https://www.python.org/downloads/
- **Usage**: Execute `.py` files
- **Test**: `python --version`

#### JavaScript
- **Status**: Optional
- **Runtime**: Node.js 12.0+
- **Detection**: Checks for `node` or `node.exe` in PATH
- **Installation**: https://nodejs.org/
- **Usage**: Execute `.js` files
- **Test**: `node --version`

#### Ruby
- **Status**: Optional
- **Version**: 2.5+
- **Detection**: Checks for `ruby` or `ruby.exe` in PATH
- **Installation**: https://www.ruby-lang.org/en/downloads/
- **Usage**: Execute `.rb` files
- **Test**: `ruby --version`

#### Lua
- **Status**: Optional
- **Version**: 5.1+
- **Detection**: Checks for `lua` or `lua.exe` in PATH
- **Installation**: https://www.lua.org/download.html
- **Usage**: Execute `.lua` files
- **Test**: `lua -v`

#### Shell (Bash)
- **Status**: Optional
- **Requirement**: WSL (Windows Subsystem for Linux) or Git Bash
- **Detection**: Checks for `bash` in PATH
- **Installation**: 
  - WSL: `wsl --install` (Windows 11)
  - Git Bash: https://git-scm.com/download/win
- **Usage**: Execute `.sh` files
- **Test**: `bash --version`

## Installation Instructions

### Install All Optional Dependencies

#### Python
```batch
# Windows PowerShell as Admin
winget install Python.Python.3.12
```

#### Node.js
```batch
winget install OpenJS.NodeJS
```

#### Ruby
```batch
winget install RubyLang.Ruby
```

#### Lua
```batch
# Manual installation recommended from lua.org
```

#### Bash/WSL
```batch
# Windows PowerShell as Admin
wsl --install -d Ubuntu
```

### Verify Installation
After installation, verify that interpreters are in PATH:

```batch
python --version
node --version
ruby --version
lua -v
bash --version
```

## Dependency Detection

The Updating Executor automatically detects available interpreters and displays their status:

```
[INFO] Validating dependencies...
[OK] Python installed
[OK] PowerShell installed
[OK] Batch support available
[INFO] JavaScript not found (Node.js required)
[INFO] Ruby not found
[INFO] Lua not found
[INFO] Shell not found
```

## Architecture Compatibility

### Single-File Design
The entire executor is contained in a single `run.bat` file (~600 lines). It:
- Auto-generates helper scripts in `run_space/` on first run
- Requires no external tools or libraries
- Self-configures based on available interpreters
- Cleans up after itself

### Helper Scripts Generated at Runtime
1. **read_clipboard.ps1** - PowerShell script for clipboard handling
2. **strip_bom.bat** - Batch script for BOM removal
3. **execute_code.bat** - Code execution wrapper
4. Individual `.py`, `.js`, `.rb`, `.lua`, `.sh` test/execution scripts

## Limitations

### Windows-Only
- Currently Windows-only due to:
  - Batch script format
  - Windows-specific PowerShell features
  - Win32 API calls in helper scripts

### Language Support
- Languages not in `LANGUAGES` setting in `settings.ini` will not execute
- Default supported: Python, PowerShell, Batch

## Troubleshooting

### Python not detected?
```batch
# Check if Python is in PATH
where python
# If not found, add Python directory to PATH
setx PATH "%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312"
```

### Node.js not detected?
```batch
# Check Node.js installation
where node
# Reinstall from nodejs.org if needed
```

### Script generation fails?
```batch
# Run in debug mode
# Edit settings.ini: DEBUG=1
# This will show helper script generation status
```

## Performance Notes

- **Memory**: <50MB typical usage
- **Disk**: <5MB for full installation with all helpers
- **Startup**: <2 seconds for initialization
- **Execution**: Depends on code complexity and interpreter performance

## Security Considerations

### Execution Environment
- Code runs in isolated `run_space/` directory
- No system-wide modifications
- All temporary files confined to `run_space/`
- Automatic cleanup of temporary files

### Clipboard Content
- Only used if explicitly provided
- Never uploaded or transmitted
- Only stored temporarily in `run_space/clip_input.txt`
- Cleaned up after execution

## Version Information

| Component | Current Version | Minimum Required |
|-----------|-----------------|------------------|
| Windows | 7+ | 7 |
| PowerShell | 5.0+ | 5.0 |
| Python | 3.x | 3.6 |
| Node.js | 14+ | 12.0 |
| Ruby | 2.7+ | 2.5 |
| Lua | 5.3 | 5.1 |
| Bash | 4.0+ | 3.2 |

## Support & Updates

For detailed documentation, see:
- `run_space/README.md` - Program overview
- `settings.ini` - Configuration options
- Logs in `run_space/log/` - Execution history

To check for updates or report issues:
- Review version in `settings.ini`
- Check log files for errors
- Verify PATH environment variable
