# FileWatcher.ps1 - File system monitoring for settings.ini
# Detects external modifications and triggers reload

function Initialize-FileWatcher {
    <#
    .SYNOPSIS
    Sets up FileSystemWatcher to monitor settings.ini for external changes
    #>
    param([string]$SettingsFile, [string]$ScriptDir)
    
    try {
        if ($script:FileWatcher) {
            $script:FileWatcher.EnableRaisingEvents = $false
            $script:FileWatcher.Dispose()
        }
        
        $script:FileWatcher = New-Object System.IO.FileSystemWatcher
        $script:FileWatcher.Path = $ScriptDir
        $script:FileWatcher.Filter = 'settings.ini'
        $script:FileWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size
        $script:FileWatcher.EnableRaisingEvents = $true
        
        # Store initial modified time
        if (Test-Path $SettingsFile) {
            $script:LastModifiedTime = (Get-Item $SettingsFile).LastWriteTime
        }
        
        Write-Log "File watcher initialized for settings.ini"
    } catch {
        Write-Log "WARNING: Could not initialize file watcher: $_" 'WARN'
    }
}

function Test-SettingsFileChanged {
    <#
    .SYNOPSIS
    Checks if settings.ini was modified externally
    #>
    param([string]$SettingsFile)
    
    if (-not (Test-Path $SettingsFile)) { return $false }
    
    try {
        $currentModified = (Get-Item $SettingsFile).LastWriteTime
        if ($script:LastModifiedTime -and $currentModified -gt $script:LastModifiedTime) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Update-LastModifiedTime {
    <#
    .SYNOPSIS
    Updates the tracked last modified time after internal saves
    #>
    param([string]$SettingsFile)
    
    if (Test-Path $SettingsFile) {
        $script:LastModifiedTime = (Get-Item $SettingsFile).LastWriteTime
    }
}

function Stop-FileWatcher {
    <#
    .SYNOPSIS
    Disposes the file watcher resource
    #>
    if ($script:FileWatcher) {
        try {
            $script:FileWatcher.EnableRaisingEvents = $false
            $script:FileWatcher.Dispose()
            Write-Log "File watcher disposed"
        } catch {
            Write-Log "Failed to dispose file watcher: $_" 'WARN'
        }
    }
}

Export-ModuleMember -Function Initialize-FileWatcher, Test-SettingsFileChanged, Update-LastModifiedTime, Stop-FileWatcher
