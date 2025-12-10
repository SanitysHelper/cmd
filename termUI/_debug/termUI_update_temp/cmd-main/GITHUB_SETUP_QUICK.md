# GitHub Auto-Update System - Command Reference

## Quick Commands

### Check Current Version
```powershell
cd termUI
.\powershell\termUI.ps1 --version
```

### View Changelog
```powershell
cd termUI
.\powershell\termUI.ps1 --changelog
```

### Check GitHub for Updates
```powershell
cd termUI
.\GitHub-VersionCheck.ps1
```

### Release New Version (Before Pushing to GitHub)
```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("Feature 1", "Feature 2", "Bug fix")
```

## Next Steps

1. **Create GitHub Release**
   - Go to: https://github.com/SanitysHelper/cmd/releases/new
   - Tag: `v1.0.0`
   - Title: `termUI v1.0.0`
   - Click "Publish release"

2. **Test Version Checker**
   ```powershell
   .\GitHub-VersionCheck.ps1
   ```

3. **For Each Update**
   - Update VERSION.json with `VERSION_UPDATER.ps1`
   - Push to GitHub
   - Create matching release tag

## Files & Locations

| File | Purpose |
|------|---------|
| `VERSION.json` | Version data |
| `VERSION_UPDATER.ps1` | Update version |
| `GitHub-VersionCheck.ps1` | Check for updates |
| `GITHUB_INTEGRATION.md` | Setup guide |
| `VERSIONING_QUICK_REF.md` | Version commands |
| `powershell/modules/VersionManager.ps1` | Version API |

## Status

✅ Ready for production  
✅ Synced to all termUI copies  
✅ GitHub integration enabled  

**Create first release to activate!**
