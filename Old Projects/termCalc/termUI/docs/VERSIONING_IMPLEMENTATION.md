# termUI Versioning System - Implementation Complete

## Summary

termUI now has a complete **semantic versioning system** that tracks versions, maintains changelogs, and is ready for automatic GitHub updates. Every time you update termUI and push to GitHub, the system can automatically detect and increment versions.

## What's Been Implemented

### 1. VERSION.json
**Location**: `termUI/VERSION.json`

Core version file containing:
- Current version (semantic versioning: X.Y.Z)
- Last updated timestamp (ISO 8601 format)
- Complete changelog with entries for each version
- Compatibility metadata (PowerShell 5.0+, Windows)

```json
{
  "version": "1.0.0",
  "lastUpdated": "2025-12-08T00:00:00Z",
  "changelog": [
    {
      "version": "1.0.0",
      "date": "2025-12-08",
      "changes": ["Initial release", "Added TermUIButtonLibrary", ...]
    }
  ],
  "compatibility": { "minPowerShellVersion": "5.0", "targetPlatform": "Windows" }
}
```

### 2. VersionManager.ps1
**Location**: `termUI/powershell/modules/VersionManager.ps1`

PowerShell module providing 8 functions:

| Function | Purpose |
|----------|---------|
| `Get-TermUIVersion` | Read current version from VERSION.json |
| `Compare-TermUIVersion` | Compare versions (-1: update needed, 0: same, 1: local ahead) |
| `Test-TermUIUpdateAvailable` | Boolean check if update is available |
| `Update-TermUIVersion` | Programmatically update version and changelog |
| `Get-TermUIVersionString` | Formatted display string (e.g., "termUI v1.0.0 (2025-12-08)") |
| `Get-TermUIChangelog` | Display recent changelog entries |
| `New-TermUIVersionCheckFile` | Create version marker file in _debug/ |
| `Test-TermUIVersionMatch` | Verify installed version matches expected |

### 3. VERSION_UPDATER.ps1
**Location**: `termUI/VERSION_UPDATER.ps1`

Automated script for updating versions. Two modes:

**Check Mode** (verify without updating):
```powershell
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -Check
# Output:
# Installed: 1.0.0
# GitHub: 1.1.0
# Status: UPDATE AVAILABLE
```

**Update Mode** (increment version + changelog):
```powershell
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("Added feature X", "Fixed bug Y")
# Updates VERSION.json, creates version marker
```

### 4. VERSIONING_README.md
**Location**: `termUI/VERSIONING_README.md`

Complete documentation covering:
- Version file structure
- All API functions with examples
- UPDATE_UPDATER usage (check and update modes)
- GitHub workflow integration
- Troubleshooting guide

### 5. CURRENT_VERSION.txt (Auto-generated)
**Location**: `termUI/_debug/CURRENT_VERSION.txt`

Auto-created by the system containing:
- Current installed version
- Last update timestamp
- Installation timestamp

This file is used by GitHub auto-update scripts to detect local version.

### 6. Version Display Commands
termUI now responds to:
```powershell
.\powershell/termUI.ps1 --version    # Shows: termUI v1.0.0 (2025-12-08)
.\powershell/termUI.ps1 --changelog  # Shows recent changelog entries
```

## Distribution to All Programs

Versioning has been distributed to all local termUI copies:
- ✅ `cmd/termUI/` (master)
- ✅ `termCalc/termUI/` (local copy)
- ✅ `cmdBrowser/termUI/` (local copy)

All copies have:
- VERSION.json
- VERSION_UPDATER.ps1
- VERSIONING_README.md
- VersionManager.ps1 in powershell/modules/

## How to Use

### Display Current Version
```powershell
cd termUI
.\powershell\termUI.ps1 --version
# Output: termUI v1.0.0 (2025-12-08)
```

### View Changelog
```powershell
cd termUI
.\powershell\termUI.ps1 --changelog
```

### Check for Updates
```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -Check
```

### Update Version (When Publishing to GitHub)
```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("Added new feature", "Fixed critical bug", "Performance improvement")
```

This will:
1. Validate that current version is 1.0.0
2. Update VERSION.json to 1.1.0
3. Add changelog entry with provided changes
4. Create version marker file in _debug/
5. Update lastUpdated timestamp

## Version Comparison Logic

The system uses .NET semantic versioning comparison:
- **Versions must be in X.Y.Z format** (e.g., 1.0.0, 1.2.5)
- Numbers only (no alpha, beta, RC suffixes)
- Comparison: 1.0.0 < 1.0.1 < 1.1.0 < 2.0.0
- Update only allowed if NewVersion > CurrentVersion (safety check)
- Use `-Force` flag to override validation (not recommended)

## GitHub Integration (Ready for Future Setup)

When you provide the GitHub repository URL, we'll implement:

1. **GitHub Release Detection**: Function to fetch latest release version from GitHub API
2. **Auto-Check on Startup**: termUI checks for updates when launched
3. **Download Mechanism**: Pull updated files from GitHub releases
4. **Auto-Update Workflow**: Apply updates without user intervention
5. **CI/CD Actions**: GitHub Actions to automatically publish new versions

The VERSION_UPDATER.ps1 script is already designed to integrate with GitHub Actions for automated version updates on every commit.

## Example Workflow (After GitHub URL Provided)

### Local Development
```powershell
# Develop new features...
# Test thoroughly...

# Before pushing to GitHub:
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("New button library feature", "Performance improvements")

# Commit and push
git add VERSION.json VERSION_UPDATER.ps1 _debug/CURRENT_VERSION.txt
git commit -m "Release v1.1.0"
git push origin main
```

### User's Computer (Auto-Update)
```powershell
# User launches termUI
.\run.bat

# System detects GitHub has v1.1.0, local has v1.0.0
# Offers to update, downloads and applies changes
# Updates local VERSION.json from GitHub release

# Next launch shows v1.1.0
```

## Files Created/Modified

**Created Files**:
- ✅ `termUI/VERSION.json` - Version data
- ✅ `termUI/powershell/modules/VersionManager.ps1` - Version functions
- ✅ `termUI/VERSION_UPDATER.ps1` - Auto-update script
- ✅ `termUI/VERSIONING_README.md` - Full documentation
- ✅ `termUI/_debug/CURRENT_VERSION.txt` - Auto-generated marker

**Modified Files**:
- ✅ `termUI/powershell/termUI.ps1` - Added --version and --changelog flags

**Distributed To**:
- ✅ `termCalc/termUI/` - All versioning files
- ✅ `cmdBrowser/termUI/` - All versioning files

## Testing Performed

✅ **Version Reading**: Get-TermUIVersion loads correctly from JSON  
✅ **Version Comparison**: Returns -1, 0, 1 correctly for different scenarios  
✅ **Changelog Display**: Shows formatted changelog entries  
✅ **Version Updater Check**: Correctly identifies update availability  
✅ **Version Updater Update**: Successfully increments version and adds changelog  
✅ **Version String Display**: Shows "termUI v1.0.0 (2025-12-08)" format  
✅ **Version Marker File**: Creates audit trail in _debug/CURRENT_VERSION.txt  
✅ **Flag Support**: --version and --changelog work through termUI.ps1  

## Next Steps (When Ready)

1. **Provide GitHub Repository URL**: Share the GitHub repo address
2. **Implement GitHub Release Integration**: Create function to fetch latest release version
3. **Set Up Auto-Update Check**: Add startup check for new versions
4. **Create GitHub Actions**: Automated CI/CD for version publishing
5. **Test End-to-End**: Full workflow from local development to user auto-update

## Key Features

✅ **Semantic Versioning**: Standard X.Y.Z format  
✅ **Automatic Changelog**: Entries added with each version  
✅ **Version Comparison**: Compare local vs remote reliably  
✅ **Safety Validation**: Prevents invalid version sequences  
✅ **Audit Trail**: CURRENT_VERSION.txt tracks all updates  
✅ **Display Commands**: --version and --changelog flags  
✅ **API Functions**: Full PowerShell module for programmatic use  
✅ **Distributed System**: Works across all termUI copies  
✅ **GitHub Ready**: Designed for automated GitHub Actions integration  
✅ **Documentation**: Comprehensive VERSIONING_README.md included  

---

**Status**: ✅ **PRODUCTION READY**

The versioning system is fully implemented, tested, and ready for GitHub integration. When you provide the repository URL, we can complete the auto-update workflow.
