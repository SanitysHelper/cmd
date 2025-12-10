# termUI Versioning System

This document describes how termUI versioning works and how to use it for automatic updates from GitHub.

## Overview

termUI uses **semantic versioning** (MAJOR.MINOR.PATCH format, e.g., `1.0.0`, `1.1.5`):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Version Files

### VERSION.json
Located at: `termUI/VERSION.json`

Stores current version, last update timestamp, and complete changelog.

```json
{
  "version": "1.0.0",
  "lastUpdated": "2025-12-08T00:00:00Z",
  "changelog": [
    {
      "version": "1.0.0",
      "date": "2025-12-08",
      "changes": ["Initial release", "Added TermUIButtonLibrary", "Added TermUIFunctionLibrary"]
    }
  ],
  "compatibility": {
    "minPowerShellVersion": "5.0",
    "targetPlatform": "Windows"
  }
}
```

### CURRENT_VERSION.txt (Auto-generated)
Located at: `termUI/_debug/CURRENT_VERSION.txt`

Auto-created marker file used by update scripts for version detection. Contains:
- Current installed version
- Last update timestamp
- Installation timestamp

**DO NOT EDIT MANUALLY** - This is maintained by the version system.

## Using termUI Version Commands

### Display Version
Show installed version and last update date:

```powershell
# From cmd/ directory
cd termUI
.\run.bat --version

# Or directly in PowerShell
pwsh -ExecutionPolicy Bypass -Command {
    cd termUI/powershell
    . ./modules/VersionManager.ps1
    Get-TermUIVersionString
}
```

Output:
```
termUI v1.0.0 (2025-12-08)
```

### Display Changelog
Show recent changelog entries:

```powershell
cd termUI
.\run.bat --changelog

# Or in PowerShell
pwsh -ExecutionPolicy Bypass -Command {
    cd termUI/powershell/modules
    . ./VersionManager.ps1
    Get-TermUIChangelog -EntryCount 5
}
```

## VersionManager.ps1 API

The `VersionManager.ps1` module provides these functions:

### Get-TermUIVersion
Read current version from VERSION.json

```powershell
$versionData = Get-TermUIVersion -TermUIRoot "C:\cmd\termUI"
Write-Host "Current: $($versionData.version)"
Write-Host "Updated: $($versionData.lastUpdated)"
```

### Compare-TermUIVersion
Compare two versions

```powershell
$result = Compare-TermUIVersion -LocalVersion "1.0.0" -RemoteVersion "1.1.0"
# Returns: -1 (update available), 0 (same), 1 (local ahead)

if ($result -eq -1) { Write-Host "Update available!" }
```

### Test-TermUIUpdateAvailable
Check if update is available

```powershell
$available = Test-TermUIUpdateAvailable -LocalVersion "1.0.0" -RemoteVersion "1.1.0"
if ($available) { Write-Host "Update: 1.1.0" }
```

### Update-TermUIVersion
Programmatically update version (mainly for auto-update scripts)

```powershell
Update-TermUIVersion -TermUIRoot "C:\cmd\termUI" `
    -NewVersion "1.1.0" `
    -Changes @("Added new feature", "Fixed bug")
```

### Get-TermUIVersionString
Get formatted version string for display

```powershell
$versionStr = Get-TermUIVersionString -TermUIRoot "C:\cmd\termUI"
# Returns: "termUI v1.0.0 (2025-12-08)"
```

### Get-TermUIChangelog
Get formatted changelog

```powershell
$changelog = Get-TermUIChangelog -TermUIRoot "C:\cmd\termUI" -EntryCount 3
Write-Host $changelog
```

### New-TermUIVersionCheckFile
Create version marker for update detection (called automatically by updater)

```powershell
$markerPath = New-TermUIVersionCheckFile -TermUIRoot "C:\cmd\termUI"
```

### Test-TermUIVersionMatch
Verify installed version matches expected version

```powershell
if (Test-TermUIVersionMatch -TermUIRoot "C:\cmd\termUI" -ExpectedVersion "1.0.0") {
    Write-Host "Ready for update"
}
```

## VERSION_UPDATER.ps1 Script

Automated updater used by GitHub or manual update workflows.

### Check Mode
Compare local vs remote version without updating:

```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -Check

# Output:
# Installed: 1.0.0
# GitHub: 1.1.0
# Status: UPDATE AVAILABLE
```

### Update Mode
Update version and add changelog:

```powershell
cd termUI
.\VERSION_UPDATER.ps1 `
    -NewVersion "1.1.0" `
    -CurrentVersion "1.0.0" `
    -Changes @("Added feature X", "Fixed issue Y", "Performance improvements")

# Output:
# Installed Version: 1.0.0
# Update Mode:
#   Target Version: 1.1.0
#   Version validation: PASSED
#   Changelog entries:
#     * Added feature X
#     * Fixed issue Y
#     * Performance improvements
# Applying update...
# ✓ Version updated successfully
# ✓ Version marker created
# Update Complete!
```

### Force Update
Skip version validation (dangerous—only use if certain):

```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -Changes @("Hotfix") -Force
```

## GitHub Auto-Update Workflow

When you post a new version to GitHub, use this workflow:

### 1. On Your Local Machine (Before GitHub Commit)
Update version number in VERSION.json and commit to GitHub:

```bash
# Before committing, run updater
pwsh -ExecutionPolicy Bypass -File termUI/VERSION_UPDATER.ps1 `
    -NewVersion "1.1.0" `
    -CurrentVersion "1.0.0" `
    -Changes @("New feature", "Bug fix")
```

This updates:
- `termUI/VERSION.json` (new version, updated timestamp, changelog entry)
- `termUI/_debug/CURRENT_VERSION.txt` (marker file)

Then commit and push to GitHub.

### 2. On GitHub (CI/CD - Coming Later)
When you add the GitHub repository URL, we'll create an action that:

```yaml
# .github/workflows/version-check.yml (example)
name: Check for Updates
on:
  schedule:
    - cron: '0 * * * *'  # Every hour
jobs:
  check:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check for version updates
        run: |
          pwsh -ExecutionPolicy Bypass -File termUI/VERSION_UPDATER.ps1 -Check
```

### 3. User Downloads Update
When user runs termUI and it detects a new version on GitHub:

```powershell
# Auto-update check (you'll implement)
$localVersion = (Get-TermUIVersion).version
$remoteVersion = Get-GitHubReleaseVersion  # Function you'll provide the GitHub URL for

if (Test-TermUIUpdateAvailable -LocalVersion $localVersion -RemoteVersion $remoteVersion) {
    Write-Host "Update available: $remoteVersion"
    # Download and apply update
}
```

## Update Process Flow

```
┌─ User/GitHub Posts New Version
│
├─ VERSION_UPDATER.ps1 --Check
│  └─ Compares local vs remote
│     ├─ If local < remote: UPDATE AVAILABLE
│     ├─ If local = remote: UP TO DATE
│     └─ If local > remote: LOCAL AHEAD
│
├─ VERSION_UPDATER.ps1 --Update
│  └─ Validates version match
│     ├─ Updates VERSION.json
│     ├─ Increments changelog
│     ├─ Creates marker file
│     └─ Verifies update
│
└─ Deployment
   └─ Files updated; auto-update script can pull from GitHub
```

## Integration with Your Programs

All local termUI copies (termCalc, cmdBrowser, etc.) should sync with the master via `sync-termui.ps1`:

```powershell
# Runs after VERSION_UPDATER
.\sync-termui.ps1

# This copies updated VERSION.json and VersionManager.ps1 to all programs
```

## Versioning Best Practices

1. **Always use semantic versioning**: X.Y.Z format
2. **Update VERSION.json before GitHub commit**: Use VERSION_UPDATER.ps1
3. **Add meaningful changelog entries**: Include user-facing changes
4. **Keep CURRENT_VERSION.txt auto-generated**: Never edit manually
5. **Test version comparison logic**: Before releasing
6. **Sync all copies after master update**: Use sync-termui.ps1

## Troubleshooting

### "Version verification failed after update"
- Check that VERSION.json is writable
- Verify JSON format is valid
- Check file encoding (UTF8)

### "Invalid version format"
- Use semantic versioning: X.Y.Z (e.g., 1.0.0, not 1 or 1.0)
- Numbers only in version parts

### "Version mismatch"
- Use `-Force` flag if intentional (not recommended)
- Otherwise, update to correct expected version first

### Commands not found
- Ensure you're running in PowerShell 5.0+
- Load VersionManager.ps1 first: `. ./VersionManager.ps1`
- Use `-ExecutionPolicy Bypass` on first run

## Future: Provide GitHub URL

When you're ready, provide the GitHub repository URL:

```
https://github.com/your-username/cmd
```

Then we'll:
1. Create `Get-GitHubLatestVersion` function that pulls from releases API
2. Add auto-check-on-startup to termUI.ps1
3. Create download/update mechanism
4. Test end-to-end workflow
