# ============================================================================
# DATA MANAGEMENT MODULE
# ============================================================================
# Handles button list CSV I/O, settings file reading, and button indexing

function Read-ButtonList {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @()
    }
    
    $lines = @(Get-Content -Path $FilePath -Encoding UTF8)
    if ($lines.Count -lt 2) { return @() }
    
    $headers = $lines[0] -split ',' | ForEach-Object { $_.Trim() }
    $buttons = @()
    
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $parts = $line -split ',(?=(?:[^"]*"[^"]*")*[^"]*$)' | ForEach-Object { $_.Trim().Trim('"') }
        
        $button = @{}
        for ($j = 0; $j -lt $headers.Count; $j++) {
            if ($j -lt $parts.Count) {
                $button[$headers[$j]] = $parts[$j]
            }
        }
        
        if ($button.Name -and $button.Path -and $button.Type) {
            $buttons += $button
        }
    }
    
    return $buttons
}

function Write-ButtonList {
    param(
        [array]$Buttons,
        [string]$FilePath
    )
    
    $csv = "Name,Description,Path,Type,Value`n"
    foreach ($button in $Buttons) {
        $value = if ($button.ContainsKey('Value')) { $button.Value } else { "" }
        $csv += "`"$($button.Name)`",`"$($button.Description)`",$($button.Path),$($button.Type),`"$value`"`n"
    }
    
    Set-Content -Path $FilePath -Value $csv.TrimEnd() -Encoding UTF8
}

function Initialize-ButtonIndex {
    $buttons = Read-ButtonList -FilePath $script:buttonListPath
    $script:buttonIndex.Clear()
    
    foreach ($button in $buttons) {
        $script:buttonIndex[$button.Path] = $button
    }
    
    Log-Important "Loaded $($buttons.Count) buttons from button.list"
}

function Read-SettingsFile {
    param([string]$FilePath)
    
    $settings = @{
        General = @{}
        Colors = @{}
        Logging = @{}
    }
    
    if (-not (Test-Path $FilePath)) {
        $settings.General['default_mode'] = 'numbered'
        $settings.General['enable_colors'] = $true
        $settings.General['keep_open_after_selection'] = $true
        $settings.Colors['highlight_color'] = 'Green'
        $settings.Colors['shift_color'] = 'Yellow'
        $settings.Colors['arrow_color'] = 'Cyan'
        $settings.Colors['error_color'] = 'Red'
        $settings.Logging['log_navigation'] = $true
        $settings.Logging['log_input'] = $true
        $settings.Logging['log_important'] = $true
        $settings.Logging['log_error'] = $true
        $settings.Logging['log_transcript'] = $true
        return $settings
    }
    
    $currentSection = $null
    $lines = @(Get-Content -Path $FilePath -Encoding UTF8)
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        
        if ($line -match '^\[(.+)\]$') {
            $currentSection = $matches[1]
            if (-not $settings.ContainsKey($currentSection)) {
                $settings[$currentSection] = @{}
            }
        }
        elseif ($line -match '^(.+?)=(.*)$' -and $currentSection) {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            if ($value -eq 'true') { $value = $true }
            elseif ($value -eq 'false') { $value = $false }
            
            $settings[$currentSection][$key] = $value
        }
    }
    
    return $settings
}

function Initialize-Settings {
    $script:settings = Read-SettingsFile -FilePath $script:settingsPath
    # Apply defaults if missing
    if (-not $script:settings.General.ContainsKey('keep_open_after_selection')) {
        $script:settings.General['keep_open_after_selection'] = $true
    }
    if (-not $script:settings.General.ContainsKey('debug_slow_mode')) {
        $script:settings.General['debug_slow_mode'] = $false
    }
    if (-not $script:settings.Logging.ContainsKey('log_transcript')) {
        $script:settings.Logging['log_transcript'] = $true
    }
    $script:keepOpenAfterSelection = [bool]$script:settings.General['keep_open_after_selection']
    $script:debugSlowMode = [bool]$script:settings.General['debug_slow_mode']
    $script:autoClose = $false
    if ($script:scriptDir -match "_debug\\automated_testing_environment") { $script:autoClose = $true }
    if ($env:UIBUILDER_AUTOCLOSE -eq '1' -or $env:UIBUILDER_AUTOCLOSE -eq 'true') { $script:autoClose = $true }
    if ($script:settings.Logging.log_transcript) {
        "=== Session $(Get-Timestamp) ===" | Set-Content -Path $script:transcriptPath -Encoding UTF8
    }
    Log-Important "Settings loaded from settings.ini"
}

function Test-PathValid {
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ($Path -notmatch '^[a-zA-Z0-9_.]+$') { return $false }
    return $true
}

function Test-TypeValid {
    param([string]$Type)
    
    return $Type -in @('submenu', 'option')
}

function Test-DuplicatePath {
    param([string]$Path)
    
    return $script:buttonIndex.ContainsKey($Path)
}

function Get-ChildButtons {
    param([string]$ParentPath)
    
    $children = @()
    foreach ($path in $script:buttonIndex.Keys) {
        $pathParts = $path -split '\.'
        $parentParts = $ParentPath -split '\.'
        
        # Check if this path is a direct child (one level deeper)
        if ($pathParts.Count -eq ($parentParts.Count + 1)) {
            # Check if all parent parts match
            $isChild = $true
            for ($i = 0; $i -lt $parentParts.Count; $i++) {
                if ($pathParts[$i] -ne $parentParts[$i]) {
                    $isChild = $false
                    break
                }
            }
            
            if ($isChild) {
                $children += $script:buttonIndex[$path]
            }
        }
    }
    
    # Sort children by their path to maintain consistent order
    if ($children.Count -gt 1) {
        $children = $children | Sort-Object { $_.Path }
    }
    
    # Return array of children (may be empty)
    return $children
}

function Add-ButtonOption {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Path,
        [string]$Type
    )
    
    if (-not (Test-PathValid -Path $Path)) {
        Log-Error "Invalid path format: $Path"
        return $false
    }
    
    if (-not (Test-TypeValid -Type $Type)) {
        Log-Error "Invalid type: $Type (must be 'submenu' or 'option')"
        return $false
    }
    
    if (Test-DuplicatePath -Path $Path) {
        Log-Error "Path already exists: $Path"
        return $false
    }
    
    $script:buttonIndex[$Path] = @{
        Name = $Name
        Description = $Description
        Path = $Path
        Type = $Type
    }
    
    Save-ButtonList
    Log-Important "Added button: $Path ($Type)"
    return $true
}

function Remove-ButtonOption {
    param([string]$Path)
    
    if (-not (Test-DuplicatePath -Path $Path)) {
        Log-Error "Path not found: $Path"
        return $false
    }
    
    # Check for children
    $children = @($script:buttonIndex.Keys | Where-Object { $_ -like "$Path.*" })
    if ($children.Count -gt 0) {
        Log-Error "Cannot remove path with children: $Path"
        return $false
    }
    
    $script:buttonIndex.Remove($Path)
    Save-ButtonList
    Log-Important "Removed button: $Path"
    return $true
}

function Save-ButtonList {
    $buttons = @($script:buttonIndex.Values)
    Write-ButtonList -Buttons $buttons -FilePath $script:buttonListPath
}
