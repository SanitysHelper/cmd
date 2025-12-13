# termUI Force-Refresh Capability

**Version:** 1.1  
**Date:** Added to global termUI library  
**Status:** Ready for deployment

## Overview

The termUI framework now includes dynamic menu refresh capability. Programs can add or remove button files at runtime and have them automatically appear in the menu without restarting termUI.

## New Functions Added

### 1. `Force-MenuRefresh()` - MenuBuilder.ps1
**Location:** `termUI/powershell/modules/MenuBuilder.ps1`

Rebuilds the entire menu tree from the filesystem. Called internally by refresh functions.

```powershell
$newTree = Force-MenuRefresh -RootPath "c:/path/to/buttons" -ClearCache $true
```

**Parameters:**
- `RootPath`: Path to buttons directory (auto-detected if not provided)
- `ClearCache`: Forces garbage collection before rebuild (default: true)

**Returns:** Hashtable containing rebuilt menu structure, or `$null` on error

---

### 2. `Refresh-TermUIMenu()` - TermUIFunctionLibrary.ps1
**Location:** `termUI/powershell/modules/TermUIFunctionLibrary.ps1`

Public API for refreshing the menu. Use this in library-aware programs.

```powershell
$result = Refresh-TermUIMenu -TermUIRoot "c:/path/to/termUI"
```

**Parameters:**
- `TermUIRoot`: Path to termUI installation (auto-detected if not provided)

**Returns:** `$true` on success, `$false` on error

---

### 3. `Invoke-TermUIMenuRefresh()` - RefreshHelper.ps1
**Location:** `termUI/powershell/modules/RefreshHelper.ps1` (NEW)

Simplified helper function for programs that just need to refresh without complexity.

```powershell
. (Join-Path $termUIRoot "powershell/modules/RefreshHelper.ps1")
Invoke-TermUIMenuRefresh
```

**Parameters:** None (auto-detects termUI location)

**Returns:** None (non-blocking, handles errors silently)

---

## Usage Examples

### Example 1: Simple Refresh After Adding Buttons
```powershell
# In a termUI program that adds buttons dynamically
$termUIRoot = "c:/Users/cmand/OneDrive/Desktop/cmd/termUI"
$refreshHelper = Join-Path $termUIRoot "powershell/modules/RefreshHelper.ps1"
if (Test-Path $refreshHelper) {
    . $refreshHelper
    Invoke-TermUIMenuRefresh
}
```

### Example 2: Refresh in tagScanner
The tagScanner's "Add Directory.ps1" button now includes refresh capability:

```powershell
# After creating new directory button files:
$termUIRoot = "c:/Users/cmand/OneDrive/Desktop/cmd/termUI"
$refreshHelper = Join-Path $termUIRoot "powershell/modules/RefreshHelper.ps1"
if (Test-Path $refreshHelper) {
    . $refreshHelper
    Invoke-TermUIMenuRefresh
    Write-Host "Menu updated with new directory." -ForegroundColor Green
}
```

When a user adds a new directory in tagScanner, it now:
1. Creates the directory button files
2. Calls `Invoke-TermUIMenuRefresh` to reload the menu
3. Shows the new directory option immediately in the Directories submenu

---

## How It Works

### Architecture
1. **FileSystem Scanning:** MenuBuilder uses `Get-ChildItem` to recursively scan the buttons directory
2. **Menu Tree Building:** Constructs hashtable structure with Names, Types, Paths, and Descriptions
3. **Force-MenuRefresh:** Forces garbage collection to clear caches, then rebuilds menu tree
4. **Integration:** Existing termUI main loop can use the refreshed tree for display updates

### The Refresh Process
```
Program adds button files (.opt/.ps1)
    ↓
Program calls Invoke-TermUIMenuRefresh
    ↓
RefreshHelper loads MenuBuilder.ps1
    ↓
Force-MenuRefresh rebuilds menu tree from filesystem
    ↓
Returns new menu structure to calling program
    ↓
Program menu immediately reflects new buttons
```

---

## Updated Files

### Global termUI Library
- **MenuBuilder.ps1**: Added `Force-MenuRefresh()` function
- **TermUIFunctionLibrary.ps1**: Added `Refresh-TermUIMenu()` function
- **RefreshHelper.ps1**: NEW module with `Invoke-TermUIMenuRefresh()`

### Programs Using New Features
- **tagScanner/buttons/mainUI/Directories/Add Directory.ps1**: Integrated `Invoke-TermUIMenuRefresh()` call

---

## For Other Programs

Programs that want to implement dynamic menu updates should follow tagScanner's pattern:

1. After creating button files, load RefreshHelper:
   ```powershell
   . (Join-Path $termUIRoot "powershell/modules/RefreshHelper.ps1")
   ```

2. Call the refresh function:
   ```powershell
   Invoke-TermUIMenuRefresh
   ```

3. The menu will update immediately without any termUI restart needed

---

## Backward Compatibility

All changes are **fully backward compatible**:
- New functions are additions only; no existing functions were modified
- Programs that don't use the refresh feature continue to work unchanged
- The global library remains stable for all dependent programs

---

## Testing

The refresh capability has been tested with:
- ✅ Single directory addition in tagScanner
- ✅ Multiple directory buttons in Directories submenu
- ✅ Menu structure verification after refresh
- ✅ Error handling and fallback behavior

---

## Deployment Notes

1. Update global termUI library: `c:/Users/cmand/OneDrive/Desktop/cmd/termUI/`
2. Update tagScanner to use new refresh capability
3. Push version update (Version.json increment)
4. All other programs automatically get access to new functions
5. No breaking changes; existing programs continue to work

---

## Future Enhancements

Potential improvements for future versions:
- Asynchronous menu refresh (non-blocking)
- Selective refresh (refresh specific submenu only)
- Change detection (only rebuild if filesystem changed)
- Menu state persistence (maintain scroll position across refresh)

