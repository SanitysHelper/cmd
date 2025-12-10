# SettingsIO.ps1 - Settings file I/O operations
# Handles loading and saving settings.ini files

function Load-Settings {
    <#
    .SYNOPSIS
    Loads settings from settings.ini into structured object
    
    .OUTPUTS
    Hashtable with structure: @{ Section = @{ Key = @{ Value=''; Description='' } } }
    #>
    param([string]$SettingsFile)
    
    $settings = @{}
    $currentSection = 'General'
    
    if (-not (Test-Path $SettingsFile)) {
        Write-Host "[WARN] Settings file not found: $SettingsFile" -ForegroundColor Yellow
        return $settings
    }
    
    $lines = Get-Content $SettingsFile -Encoding UTF8
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        
        # Skip empty lines and comment-only lines
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }
        
        # Section header
        if ($line -match '^\[(.+)\]$') {
            $currentSection = $matches[1]
            if (-not $settings.ContainsKey($currentSection)) {
                $settings[$currentSection] = @{}
            }
            continue
        }
        
        # Key=Value # Description format
        if ($line -match '^([^=]+)=([^#]+)(#(.+))?$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $description = if ($matches[4]) { $matches[4].Trim() } else { "No description" }
            
            if (-not $settings.ContainsKey($currentSection)) {
                $settings[$currentSection] = @{}
            }
            
            $settings[$currentSection][$key] = @{
                Value = $value
                Description = $description
            }
        }
    }
    
    Write-Log "Loaded settings from $SettingsFile"
    return $settings
}

function Save-Settings {
    <#
    .SYNOPSIS
    Saves settings back to settings.ini with formatting preserved
    Includes detailed write operation logging
    #>
    param(
        [hashtable]$Settings,
        [string]$SettingsFile
    )
    
    try {
        $output = @()
        $output += "# Settings Manager Configuration File"
        $output += "# Format: key=value  # Description"
        $output += "# Sections: [General], [Logging], [Advanced]"
        $output += ""
        
        $settingCount = 0
        foreach ($section in $Settings.Keys | Sort-Object) {
            $output += "[$section]"
            
            foreach ($key in $Settings[$section].Keys | Sort-Object) {
                $value = $Settings[$section][$key].Value
                $desc = $Settings[$section][$key].Description
                $output += "$key=$value  # $desc"
                $settingCount++
            }
            
            $output += ""
        }
        
        # Write with detailed logging
        $output | Out-File -FilePath $SettingsFile -Encoding UTF8 -Force -ErrorAction Stop
        
        # Verify the file was actually written
        if (Test-Path $SettingsFile) {
            $fileSize = (Get-Item $SettingsFile).Length
            $fileContent = Get-Content $SettingsFile -ErrorAction SilentlyContinue
            $lineCount = if ($fileContent) { @($fileContent).Count } else { 0 }
            
            Write-OperationLog -Operation 'SAVE_SETTINGS' `
                -OutputPath $SettingsFile `
                -Context "$settingCount settings" `
                -Status 'SUCCESS' `
                -Details "File size: $fileSize bytes, Lines: $lineCount"
            
            Write-Log "Saved settings to $SettingsFile ($settingCount settings, $lineCount lines, $fileSize bytes)"
            Write-Host "[INFO] Settings saved successfully." -ForegroundColor Green
            
            # Update last modified time to prevent false change detection
            Update-LastModifiedTime
        } else {
            throw "Settings file was not created after write operation"
        }
    } catch {
        Write-OperationLog -Operation 'SAVE_SETTINGS' `
            -OutputPath $SettingsFile `
            -Status 'FAILED' `
            -Details $_
        
        Write-Log "FAILED to save settings: $_" 'ERROR'
        Write-Host "[ERROR] Failed to save settings: $_" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Load-Settings, Save-Settings
