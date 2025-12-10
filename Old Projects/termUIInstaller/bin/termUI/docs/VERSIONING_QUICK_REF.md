# termUI Versioning - Quick Reference

## View Version
```powershell
cd termUI
.\powershell\termUI.ps1 --version
# termUI v1.0.0 (2025-12-08)
```

## View Changelog
```powershell
cd termUI
.\powershell\termUI.ps1 --changelog
```

## Check for Updates (Compare Local vs GitHub)
```powershell
cd termUI
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -Check
# Shows: UPDATE AVAILABLE / UP TO DATE / LOCAL AHEAD
```

## Update Version When Publishing to GitHub
```powershell
cd termUI

# For minor version bump (feature)
.\VERSION_UPDATER.ps1 -NewVersion "1.1.0" -CurrentVersion "1.0.0" `
    -Changes @("Added new feature", "Improved performance")

# For patch version bump (bug fix)
.\VERSION_UPDATER.ps1 -NewVersion "1.0.1" -CurrentVersion "1.0.0" `
    -Changes @("Fixed critical bug")

# For major version bump (breaking changes)
.\VERSION_UPDATER.ps1 -NewVersion "2.0.0" -CurrentVersion "1.0.0" `
    -Changes @("Major refactor", "Breaking API changes")
```

## Workflow: Before Pushing to GitHub
1. Make your changes
2. Test thoroughly
3. Update version:
   ```powershell
   cd termUI
   .\VERSION_UPDATER.ps1 -NewVersion "X.Y.Z" -CurrentVersion "A.B.C" `
       -Changes @("Change 1", "Change 2")
   ```
4. Verify:
   ```powershell
   .\powershell\termUI.ps1 --version    # Should show new version
   .\powershell\termUI.ps1 --changelog  # Should show your changes
   ```
5. Commit and push to GitHub
6. When GitHub has new version, we'll auto-download and update

## Files to Commit When Updating
- `termUI/VERSION.json` - Updated version and changelog
- `termUI/_debug/CURRENT_VERSION.txt` - Auto-updated marker (optional, for tracking)

Don't commit:
- `termUI/_runspace/` or other temp files

## Semantic Versioning Format
- **MAJOR.MINOR.PATCH** (e.g., `1.0.0`)
  - **MAJOR**: Breaking changes (X++)
  - **MINOR**: New features (Y++)
  - **PATCH**: Bug fixes (Z++)
  - Start at **1.0.0** (not 0.1.0)
  - Increment only the relevant part (1.0.0 → 1.1.0, not 1.0.1)

## Safety Features
- ✅ Prevents downgrading (can't update to lower version)
- ✅ Validates version format (X.Y.Z only)
- ✅ Verifies current version before updating
- ✅ Creates audit trail in _debug/CURRENT_VERSION.txt
- ✅ Maintains complete changelog history

## If Something Goes Wrong
- Manually edit `VERSION.json` to fix (only if absolutely necessary)
- Use `-Force` flag to skip validation: `.\VERSION_UPDATER.ps1 -Force -NewVersion "X.Y.Z"`
- Revert VERSION.json from git: `git checkout termUI/VERSION.json`

## For GitHub Auto-Updates (Coming Soon)
When you provide the GitHub URL, users will get:
- Auto-detection of new versions
- One-click download + update
- Automatic local VERSION.json update
- Seamless version sync across all programs

---

**Current Version**: termUI v1.0.0 (2025-12-08)  
**Status**: Ready for GitHub integration  
**All Systems**: Operational and tested
