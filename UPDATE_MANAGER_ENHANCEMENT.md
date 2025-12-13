# Update-Manager Enhancement: Automatic Cleanup on Failure

## Summary
Enhanced both termUI and proxyHunter Update-Manager modules to automatically delete all downloaded files if an update fails at any stage.

## Files Modified
1. `c:\cmdPrograms\cmd\termUI\powershell\modules\Update-Manager.ps1`
2. `c:\cmdPrograms\cmd\termUIPrograms\proxyHunter\powershell\modules\Update-Manager.ps1`

## Changes Made

### 1. New Function: `Remove-UpdateTemporaryFiles`
A dedicated cleanup function that safely removes both the downloaded ZIP file and the extracted temporary folder.

**Features:**
- Checks if files exist before attempting deletion
- Catches errors and logs them as warnings (doesn't break the update process)
- Provides detailed logging of cleanup actions
- Attempts to remove both ZIP and extraction folder independently

```powershell
function Remove-UpdateTemporaryFiles {
    param(
        [string]$TempZip,
        [string]$TempExtract
    )
    
    try {
        if (Test-Path $TempZip) {
            Write-Log "Removing temporary ZIP: $TempZip" "INFO"
            Remove-Item -Path $TempZip -Force -ErrorAction Stop
            Write-Log "Temporary ZIP removed successfully" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to remove temporary ZIP: $_" "WARN"
    }
    
    try {
        if (Test-Path $TempExtract) {
            Write-Log "Removing temporary extraction folder: $TempExtract" "INFO"
            Remove-Item -Path $TempExtract -Recurse -Force -ErrorAction Stop
            Write-Log "Temporary extraction folder removed successfully" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to remove temporary extraction folder: $_" "WARN"
    }
}
```

### 2. Enhanced `Install-Update` Function
The function now uses centralized cleanup function and ensures cleanup happens on any failure.

**Initialization:**
- Temp paths (`$tempZip` and `$tempExtract`) are declared at function scope for availability in both try and catch blocks

**Error Handling Points:**
1. **Download Failure** - Calls cleanup before returning false
2. **Extraction Failure** - Calls cleanup before returning false
3. **Source Folder Not Found** - Calls cleanup before returning false
4. **General Failure** - Catch-all block at end calls cleanup and logs warning

**Code Example:**
```powershell
catch {
    Write-Log "Download failed: $_" "ERROR"
    Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
    return $false
}
```

### 3. Final Cleanup Path
On successful completion (Step 5), cleanup is also called to remove temporary files:

```powershell
# Step 5: Cleanup
Write-Log "Cleaning up temporary files..."
Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract

Write-Log "Update completed successfully: $LocalVersion -> $RemoteVersion" "SUCCESS"
return $true
```

### 4. Catch-All Exception Handler
If any unexpected error occurs during update, the outer catch block ensures cleanup happens:

```powershell
catch {
    Write-Log "Update installation failed: $_" "ERROR"
    Write-Log "Performing cleanup of downloaded files due to failure..." "WARN"
    Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
    return $false
}
```

## Failure Scenarios Covered

| Scenario | Action |
|----------|--------|
| Download fails (network error, timeout, etc.) | ✅ Clean up temporary files |
| Extraction fails (corrupted ZIP, permissions) | ✅ Clean up both ZIP and extracted folder |
| Source folder missing in archive | ✅ Clean up both files |
| File copy fails (permissions, locked files) | ✅ Clean up both files |
| Unexpected error at any point | ✅ Clean up both files |
| Successful update | ✅ Clean up temporary files |

## Logging Output
When cleanup occurs due to failure, the logs now show:
```
[ERROR] Download failed: <error details>
[INFO] Removing temporary ZIP: C:\path\to\termUI_update.zip
[SUCCESS] Temporary ZIP removed successfully
[INFO] Removing temporary extraction folder: C:\path\to\termUI_update_temp
[SUCCESS] Temporary extraction folder removed successfully
```

## Benefits
1. **No Orphaned Files** - Failed updates no longer leave behind downloaded ZIP and temporary folders
2. **Automatic Cleanup** - No manual intervention needed to clean up after failed updates
3. **Disk Space** - Failed updates don't consume unnecessary disk space
4. **Better Logging** - Cleanup actions are logged for debugging
5. **Robust Error Handling** - Cleanup failures don't interrupt the update process

## Testing
Both Update-Manager files have been validated:
- ✅ termUI Update-Manager syntax valid
- ✅ proxyHunter Update-Manager syntax valid
- ✅ All cleanup function logic in place
- ✅ Error handling at all critical points
