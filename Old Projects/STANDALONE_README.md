# termUI Standalone - Single File Distribution

## ✨ What You Get

**Three standalone options - pick your favorite:**

### Option 1: **termUI.exe** (EASIEST)
- **Size**: 7.44 MB
- **Format**: Windows executable
- **Usage**: Just double-click!
- **Features**: 
  - No installation needed
  - Auto-downloads termUI from GitHub
  - Caches files in AppData\Roaming\termUI
  - Auto-updates on launch
  - First run: ~1 minute (downloads ~2 MB)
  - Subsequent runs: Instant

### Option 2: **termUI-standalone.ps1** (SMALLEST)
- **Size**: 5.7 KB
- **Format**: PowerShell script
- **Usage**: 
  ```powershell
  powershell -ExecutionPolicy Bypass -File termUI-standalone.ps1
  ```
- **Features**: Same as EXE, but portable PowerShell script

### Option 3: **termUI.bat** (CLASSIC)
- **Size**: 1 KB
- **Format**: Batch file wrapper
- **Usage**: Double-click or `termUI.bat`
- **Features**: Classic Windows batch wrapper

## 🚀 Quick Start

### Windows Users (Recommended):
1. Download the ZIP
2. Extract anywhere
3. Double-click **termUI.exe**
4. Done!

### PowerShell Users:
```powershell
powershell -ExecutionPolicy Bypass -File termUI-standalone.ps1
```

### Command Line:
```bash
.\termUI.exe --version
.\termUI.exe --check-update
.\termUI.exe --update
```

## 📋 What Happens on First Run

1. **termUI.exe** starts (7.4 MB self-contained)
2. Downloads required files from GitHub (~2 MB)
3. Caches in: `%APPDATA%\Roaming\termUI`
4. Launches termUI terminal interface
5. **Subsequent runs are instant** - uses cached files

## ⚙️ System Requirements

- **Windows 10/11** OR PowerShell 5.0+
- **Internet connection** (first run only)
- **No installation required** - runs as-is

## 🆙 Auto-Update

termUI automatically checks for updates on every launch.

Manual check/update:
```bash
termUI.exe --check-update
termUI.exe --update
```

## 🔧 Command Line Options

```bash
termUI.exe                    # Launch termUI
termUI.exe --version          # Show version
termUI.exe --changelog        # Show changelog
termUI.exe --check-update     # Check for updates
termUI.exe --update           # Install updates
```

## 📂 Cache Location

**Windows**: `C:\Users\<YourName>\AppData\Roaming\termUI`

Cache includes:
- All termUI PowerShell scripts
- Configuration files
- Menu structure
- Version information

## 🧹 Clean Up

To clean cache and force re-download:
```bash
rmdir %APPDATA%\Roaming\termUI /s /q
```

Or just run `termUI.exe --update` to refresh everything.

## 🎯 Features

✅ **Fully Self-Contained**  
✅ **No Installation Required**  
✅ **Auto-Updates from GitHub**  
✅ **Fast After First Run**  
✅ **Portable to Any Windows PC**  
✅ **No Administrator Required**  
✅ **19 Input Button Types**  
✅ **Comprehensive Logging**  
✅ **Custom Menus Support**  

## 📊 Size Comparison

| Option | Size | Type |
|--------|------|------|
| termUI.exe | 7.4 MB | Executable |
| termUI-standalone.ps1 | 5.7 KB | PowerShell Script |
| termUI.bat | 1 KB | Batch File |
| Cached termUI | 0.06 MB | Runtime files |

## 🔒 Security

- ✅ Downloaded from official GitHub repository
- ✅ Open source (inspect the code)
- ✅ No external dependencies
- ✅ No system modifications
- ✅ Runs in user AppData folder only

## 🆘 Troubleshooting

**EXE won't launch:**
- Ensure Windows Defender/Antivirus isn't blocking it
- Try right-click → Properties → Unblock
- Run as Administrator if needed

**PowerShell script won't run:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

**Updates not working:**
- Check internet connection
- Ensure GitHub is accessible
- Try: `termUI.exe --update --force`

**Clean start (reset everything):**
```powershell
rmdir $env:APPDATA\termUI -Recurse -Force -ErrorAction SilentlyContinue
.\termUI.exe
```

## 📝 Version

**termUI v1.1.0**  
**Standalone Edition**  
**December 2025**

## 🔗 Links

- **GitHub**: https://github.com/SanitysHelper/cmd
- **Issues**: https://github.com/SanitysHelper/cmd/issues
- **Docs**: Check the documentation in cached files

## 💡 Tips

1. **Create a Shortcut**: Right-click termUI.exe → Send to → Desktop
2. **Add to PATH**: Copy termUI.exe to a folder in your PATH
3. **Pin to Taskbar**: Right-click termUI.exe → Pin to Taskbar
4. **Rename as Needed**: termUI.exe can be renamed without issues

## 🎉 Ready to Go!

That's it! termUI is fully self-contained and ready to use.  
No other files needed, no installation, no hassle.

Just double-click and enjoy! 🚀

---

**termUI** - Terminal User Interface Framework  
Built with PowerShell | Self-Contained | Auto-Updating
