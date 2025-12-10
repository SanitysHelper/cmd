# termUI Documentation Index

All documentation is organized here. Choose what you need:

## 🚀 Quick Start (Start Here!)
- **[GITHUB_AUTO_UPDATE_COMPLETE.md](GITHUB_AUTO_UPDATE_COMPLETE.md)** - Complete system overview and how everything works
- **[GITHUB_INTEGRATION.md](GITHUB_INTEGRATION.md)** - Setup guide for GitHub releases and auto-update workflow

## 📋 Version Management
- **[VERSIONING_QUICK_REF.md](VERSIONING_QUICK_REF.md)** - Quick command reference for version operations
- **[VERSIONING_README.md](VERSIONING_README.md)** - Complete API documentation for VersionManager functions
- **[VERSIONING_IMPLEMENTATION.md](VERSIONING_IMPLEMENTATION.md)** - Technical implementation details

## 🎮 Feature Guides
- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** - Guide for extending termUI with new features and libraries
- **[P_KEY_QUICK_REF.md](P_KEY_QUICK_REF.md)** - Quick reference for P key (description) feature
- **[P_KEY_CHEAT_SHEET.md](P_KEY_CHEAT_SHEET.md)** - Complete cheat sheet for P key functionality
- **[BACKSPACE_FEATURE_GUIDE.md](BACKSPACE_FEATURE_GUIDE.md)** - Guide for backspace input feature
- **[MANUAL_INPUT_DETECTION.md](MANUAL_INPUT_DETECTION.md)** - How to detect and handle manual input

## ✅ Implementation Records
- **[DEVELOPMENT_COMPLETE.md](DEVELOPMENT_COMPLETE.md)** - Development completion status
- **[IMPLEMENTATION_COMPLETE_P_KEY.md](IMPLEMENTATION_COMPLETE_P_KEY.md)** - P key feature implementation summary

---

## Quick Command Reference

**Check version:**
```powershell
.\powershell\termUI.ps1 --version
```

**Check GitHub for updates:**
```powershell
.\GitHub-VersionCheck.ps1
```

**Release new version:**
```powershell
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" -Changes @("Feature", "Fix")
```

**View changelog:**
```powershell
.\powershell\termUI.ps1 --changelog
```

---

## File Organization

```
termUI/
├── VERSION.json                 # Current version
├── VERSION_UPDATER.ps1          # Update version script
├── GitHub-VersionCheck.ps1      # Check GitHub for updates
├── README.md                    # Main README
├── settings.ini                 # Settings
├── run.bat                      # Entry point
│
├── docs/                        # All documentation (this folder)
│   ├── GITHUB_AUTO_UPDATE_COMPLETE.md
│   ├── GITHUB_INTEGRATION.md
│   ├── VERSIONING_*.md
│   ├── DEVELOPMENT_*.md
│   └── ... (other guides)
│
├── powershell/
│   ├── termUI.ps1
│   └── modules/
│       ├── VersionManager.ps1
│       └── ... (other modules)
│
├── buttons/                     # UI buttons
├── csharp/                      # Input handler
└── _debug/                      # Debug files
```

---

**All guides moved here to keep root directory clean!**
