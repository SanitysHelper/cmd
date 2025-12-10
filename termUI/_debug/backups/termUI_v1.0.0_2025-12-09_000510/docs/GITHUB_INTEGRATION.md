# termUI GitHub Integration Guide

This guide explains how to set up automatic version detection and updates from GitHub.

## Current Setup

Your repository is configured for auto-updates:
- **GitHub Repo**: `https://github.com/SanitysHelper/cmd`
- **termUI Path**: `/termUI`
- **Version File**: `termUI/VERSION.json`
- **Status**: Ready for GitHub releases

## Step 1: Create First GitHub Release

To enable version checking, create a GitHub release:

### Via Web Interface (Easiest)
1. Go to: https://github.com/SanitysHelper/cmd/releases/new
2. Click "Create a new release"
3. Set:
   - **Tag version**: `v1.0.0`
   - **Release title**: `termUI v1.0.0`
   - **Description**: (optional) Add changelog details
   - **This is a pre-release**: Uncheck unless it's alpha/beta
4. Click "Publish release"

### Via Command Line (Using GitHub CLI)
```bash
# If you have gh installed
gh release create v1.0.0 -t "termUI v1.0.0" -n "Initial release"
```

Once created, the GitHub version checker will detect it.

## Step 2: Test Version Detection

After creating a release, test that version detection works:

```powershell
cd termUI
.\GitHub-VersionCheck.ps1

# Output should show:
# Local Version: 1.0.0
# GitHub Version: 1.0.0
# Result: Up to Date
```

## Step 3: Workflow for Future Updates

When you develop new features and want to publish:

### Local Development
```powershell
# 1. Make your changes and test thoroughly
# 2. Update version in termUI
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("Added new feature", "Performance improvement", "Bug fix")

# 3. Verify update worked
.\powershell\termUI.ps1 --version
.\powershell\termUI.ps1 --changelog

# 4. Commit to GitHub
git add VERSION.json _debug/CURRENT_VERSION.txt
git commit -m "Release v1.1.0: Added new features"
git push origin main
```

### Create GitHub Release
1. Go to: https://github.com/SanitysHelper/cmd/releases/new
2. Set:
   - **Tag version**: `v1.1.0`
   - **Release title**: `termUI v1.1.0`
   - **Description**: Copy changelog from CHANGELOG or VERSION.json
3. Click "Publish release"

Users with older versions will now see an update available:
```powershell
.\GitHub-VersionCheck.ps1
# Output: Update Available! (1.0.0 → 1.1.0)
```

## Using GitHub-VersionCheck.ps1

### Check for Updates
```powershell
cd termUI
.\GitHub-VersionCheck.ps1

# Shows current version, checks GitHub, compares
```

### Specify Different Repository
```powershell
.\GitHub-VersionCheck.ps1 -GitHubRepo "YourUsername/YourRepo"
```

### With GitHub Token (Higher Rate Limits)
```powershell
$token = "ghp_YourTokenHere"
.\GitHub-VersionCheck.ps1 -GitHubToken $token
```

### Integration in Scripts
```powershell
# Check for updates and store result
$versionStatus = & .\GitHub-VersionCheck.ps1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Version check completed successfully"
}
```

## Version Comparison Logic

The system compares semantic versions:
- **Local < GitHub**: Update Available
- **Local = GitHub**: Up to Date  
- **Local > GitHub**: Development/Ahead of Release

Examples:
```
1.0.0 vs 1.1.0 → UPDATE AVAILABLE
1.0.0 vs 1.0.0 → UP TO DATE
1.1.0 vs 1.0.0 → LOCAL AHEAD
```

## Semantic Versioning Guide

Follow this pattern for version numbers:

| Version | Scenario | Example |
|---------|----------|---------|
| `MAJOR.MINOR.PATCH` | Standard format | `1.0.0` |
| Increment `MAJOR` | Breaking changes | `1.0.0` → `2.0.0` |
| Increment `MINOR` | New features | `1.0.0` → `1.1.0` |
| Increment `PATCH` | Bug fixes | `1.0.0` → `1.0.1` |

**Rule**: Only increment the relevant part!
- ✅ `1.0.0` → `1.1.0` (new feature)
- ❌ `1.0.0` → `1.1.1` (don't increment patch)

## GitHub Release Best Practices

### Tag Naming
- Use semantic version with `v` prefix: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Lowercase letters only

### Release Titles
- Format: `termUI vX.Y.Z` 
- Example: `termUI v1.1.0`

### Release Descriptions
Include:
- Major features added
- Bug fixes
- Performance improvements
- Breaking changes (if any)
- Known issues

Example description:
```markdown
## Changes in v1.1.0

### Features
- Added TermUIButtonLibrary for dynamic button creation
- Improved menu rendering performance

### Bug Fixes
- Fixed backspace display issue
- Corrected version comparison logic

### Breaking Changes
None - fully backward compatible

### Known Issues
- Large menus (100+ items) may render slowly

### Install
Download from releases or use auto-update feature
```

## Files Involved in GitHub Integration

### Files You Maintain
- `termUI/VERSION.json` - Local version info
- `termUI/VERSION_UPDATER.ps1` - Update version before release

### Files for Auto-Updates (Automatic)
- `termUI/_debug/CURRENT_VERSION.txt` - Version marker (auto-created)
- `termUI/GitHub-VersionCheck.ps1` - Check GitHub for updates

### GitHub Files
- `/termUI/` folder - Entire termUI directory synced
- Git tags - `v1.0.0`, `v1.1.0`, etc.
- GitHub releases page - User-visible release info

## Troubleshooting

### No releases found (404)
**Problem**: `GitHub-VersionCheck.ps1` shows "No releases found"

**Solution**: Create a GitHub release (see Step 1 above)

### "Error connecting to GitHub API"
**Problem**: Script fails to connect to GitHub

**Solutions**:
- Check internet connection: `Test-NetConnection github.com -Port 443`
- Verify repo URL is correct: `SanitysHelper/cmd`
- Try with token for higher rate limits: `.\GitHub-VersionCheck.ps1 -GitHubToken "..."`

### Version comparison issues
**Problem**: Version comparison gives wrong result

**Solutions**:
- Ensure semantic versioning format (X.Y.Z only)
- No alpha/beta suffixes: ✅ `1.0.0` ❌ `1.0.0-beta`
- Don't skip version parts: ✅ `1.0.0 → 1.1.0` ❌ `1.0.0 → 1.1.1`

### Local version won't update
**Problem**: `VERSION_UPDATER.ps1` won't update version

**Solutions**:
- Check VERSION.json is writable
- Verify new version > old version (can't downgrade)
- Use `-Force` flag if needed: `.\VERSION_UPDATER.ps1 -Force ...`

## Advanced: Automated GitHub Actions (Optional)

For fully automated releases, you can add GitHub Actions:

```yaml
# .github/workflows/release.yml
name: Create Release
on:
  push:
    paths:
      - 'termUI/VERSION.json'
jobs:
  create-release:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Read version
        run: |
          $version = Get-Content termUI/VERSION.json | ConvertFrom-Json
          echo "VERSION=$($version.version)" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
      - name: Create release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ env.VERSION }}
          release_name: termUI v${{ env.VERSION }}
```

This would automatically create a release whenever you update VERSION.json and commit.

## Summary

✅ **Step 1**: Create a GitHub release (`v1.0.0`)
✅ **Step 2**: Test with `GitHub-VersionCheck.ps1`
✅ **Step 3**: For future updates:
   1. Use `VERSION_UPDATER.ps1` to increment version
   2. Commit and push to GitHub
   3. Create GitHub release with same tag/version

Users can now check for updates anytime with:
```powershell
.\GitHub-VersionCheck.ps1
```

---

**Status**: ✅ **GITHUB INTEGRATION READY**

Repository: https://github.com/SanitysHelper/cmd  
termUI Location: /termUI  
Auto-Update Support: Enabled
