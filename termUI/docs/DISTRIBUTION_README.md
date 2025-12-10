# termUI v1.1.0 - Distribution Package

## 📦 What's Included

**Two ways to run termUI:**

1. **termUI.exe** (Portable Launcher) - Double-click to run
2. **run.bat** (Batch Launcher) - Traditional batch file launcher

Both methods launch the same termUI application.

## 🚀 Quick Start

### Option 1: Portable EXE (Recommended)
Simply double-click **termUI.exe**

### Option 2: Batch File
Double-click **run.bat** or run from command line:
```batch
.\run.bat
```

## 📋 Command Line Options

```batch
termUI.exe --version          # Show version
termUI.exe --changelog        # Show changelog
termUI.exe --check-update     # Check for updates
termUI.exe --update           # Install updates from GitHub
```

## 🔄 Auto-Update

termUI automatically checks for updates on startup (configurable in `settings.ini`).

To manually check/install updates:
```batch
termUI.exe --update
```

## 📁 File Structure

```
termUI/
├── termUI.exe                 # Portable launcher (501 KB)
├── run.bat                    # Batch launcher
├── settings.ini               # Configuration
├── VERSION.json               # Version info
├── README.md                  # This file
├── buttons/
│   └── mainUI/               # Menu structure
│       ├── Settings/         # Configuration menus
│       ├── TextInput/        # Input buttons (19 types)
│       └── Tools/            # Tool menus
├── powershell/
│   ├── termUI.ps1           # Main application
│   ├── InputHandler.ps1     # Input handler
│   └── modules/             # Core modules
└── _debug/
    ├── logs/                # Application logs
    └── backups/             # Version backups
```

## ⚙️ Configuration

Edit `settings.ini` to customize:

```ini
[General]
debug_mode=false
ui_title=termUI
keep_open_after_selection=true

[Updates]
check_on_startup=true        # Check for updates on launch
auto_install=false           # Auto-install without prompting

[Logging]
log_input=true               # Enable/disable various logs
log_important=true
log_error=true
```

## 🎯 Button Types

termUI supports three button types:

- **(submenu)** - Navigate to submenu
- **(option)** - Select an option
- **(input)** - Prompt for text input

### Available Input Buttons (19 types)

Located in `buttons/mainUI/TextInput/`:
- Email, FilePath, DirectoryPath, URL
- IPAddress, Port, HostName
- DatabaseName, TableName, APIKey
- Date, Time, SearchQuery, Command
- Password, UserName, CustomValue
- NumberA, NumberB

## 🔧 Requirements

- Windows 10/11
- PowerShell 5.0+
- Internet connection (for auto-update only)

## 📖 Documentation

Full documentation in `docs/` directory:
- `INDEX.md` - Complete documentation index
- `INPUT_BUTTON_GUIDE.md` - Input button usage
- `CLEANUP_GUIDE.md` - Maintenance guide

## 🆘 Troubleshooting

**Problem**: termUI.exe doesn't launch
- **Solution**: Ensure all files in the termUI folder are present
- **Solution**: Right-click termUI.exe → Properties → Unblock

**Problem**: Update check fails
- **Solution**: Check internet connection
- **Solution**: Verify firewall allows PowerShell

**Problem**: Logs folder grows large
- **Solution**: Logs auto-rotate at 5MB (configurable in settings.ini)
- **Solution**: Delete old logs in `_debug/logs/`

## 📝 Version

**Current Version**: 1.1.0  
**Release Date**: 2025-12-08  
**GitHub**: https://github.com/SanitysHelper/cmd

## 🔄 Updating

termUI auto-updates from GitHub. Manual update:
```batch
termUI.exe --update
```

Updates preserve:
- Your settings.ini configuration
- All logs in _debug/logs/
- All backups in _debug/backups/

## 📧 Support

For issues or questions, check:
- GitHub Issues: https://github.com/SanitysHelper/cmd/issues
- Documentation: `docs/INDEX.md`
- Logs: `_debug/logs/error.log`

---

**termUI** - Terminal User Interface Framework  
Built with PowerShell | Auto-updating | Extensible
