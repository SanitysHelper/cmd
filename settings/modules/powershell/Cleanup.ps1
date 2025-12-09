# Cleanup.ps1 - Resource cleanup and disposal
# Handles cleanup on program exit

function Invoke-Cleanup {
    <#
    .SYNOPSIS
    Cleanup function called on exit or Ctrl+C
    #>
    param([string]$ScriptDir, [hashtable]$InternalSettings)
    
    if ($script:CleanupExecuted) { return }
    $script:CleanupExecuted = $true
    
    Write-Host "`n[INFO] Performing cleanup..." -ForegroundColor Cyan
    Write-Log "Cleanup: Starting cleanup procedure"
    
    # Ensure _runspace directory exists (renamed from run_space)
    $runSpace = Join-Path $ScriptDir '_runspace'
    if (-not (Test-Path $runSpace)) {
        $null = New-Item -ItemType Directory -Path $runSpace -Force -ErrorAction SilentlyContinue
        Write-Log "Cleanup: Created _runspace directory"
    }
    
    # Clean up temp files in _runspace if debug mode is enabled
    if ($InternalSettings.debug_mode -and (Test-Path $runSpace)) {
        try {
            Get-ChildItem $runSpace -Filter '*.tmp' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Log "Cleanup: Removed temp files from _runspace (debug mode)"
        } catch {
            Write-Log "Cleanup: Failed to clean _runspace: $_"
        }
    }
    
    # Dispose file watcher
    Stop-FileWatcher
    
    Write-Host "[INFO] Cleanup complete." -ForegroundColor Green
    Write-Log "Cleanup: Cleanup procedure completed"
}

Export-ModuleMember -Function Invoke-Cleanup
