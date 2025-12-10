<#
  Manage-Settings.ps1 - Settings Manager for cmd Workspace
  
  Purpose: View, edit, and add settings with name, value, and description
  Features:
    - Load/Save settings.ini with section support
    - Display settings in formatted table
    - Edit existing settings
    - Add new settings
    - Validate input values
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$ScriptDir = Split-Path -Parent $PSCommandPath
$SettingsFile = Join-Path $ScriptDir 'settings.ini'
$InternalConfig = Join-Path $ScriptDir '.internal_config'
$LogDir = Join-Path $ScriptDir '_debug\logs'
$LogFile = Join-Path $LogDir 'important.log'

# Ensure log directory exists
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue

# Internal configuration (for Settings Manager itself)
$InternalSettings = @{
    auto_generate_readme = $true
    log_changes = $true
    backup_on_save = $false
    validate_sections = $true
    allowed_sections = @('General', 'Logging', 'Advanced')
    debug_mode = $false
    timeout_seconds = 300
    admin_password = 'admin'
}

# Script start time for timeout tracking
$script:StartTime = Get-Date
$script:CleanupExecuted = $false
$script:FileWatcher = $null
$script:LastModifiedTime = $null
$script:SettingsReloadNeeded = $false

# Load internal config if exists, create if missing
if (Test-Path $InternalConfig) {
    try {
        $configLines = Get-Content $InternalConfig -ErrorAction SilentlyContinue
        foreach ($line in $configLines) {
            if ($line -match '^([^=]+)=(.+?)(?:\s*#.*)?$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                if ($key -eq 'allowed_sections') {
                    $InternalSettings[$key] = $value -split ',' | ForEach-Object { $_.Trim() }
                } elseif ($value -ieq 'true') {
                    $InternalSettings[$key] = $true
                } elseif ($value -ieq 'false') {
                    $InternalSettings[$key] = $false
                } else {
                    $InternalSettings[$key] = $value
                }
            }
        }
    } catch {
        # Use defaults if config load fails
    }
} else {
    # Create default internal config file
    $defaultConfig = @"
# Settings Manager Internal Configuration
# This file controls the Settings Manager program itself

auto_generate_readme=true  # Automatically generate README.md on first run
log_changes=true  # Log all setting modifications to important.log
backup_on_save=false  # Create backup before saving settings
validate_sections=true  # Validate section names against allowed list
allowed_sections=General,Logging,Advanced  # Comma-separated list of allowed sections
debug_mode=false  # Enable debug features (T=test program, I=internal config editor)
timeout_seconds=300  # Execution timeout (0 to disable)
admin_password=admin  # Password required to enable debug mode
"@
    $defaultConfig | Out-File -FilePath $InternalConfig -Encoding UTF8 -Force
}

function Write-Log {
    param([string]$Message, [string]$Type = 'INFO')
    if (-not $InternalSettings.log_changes) { return }
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    "[$stamp] [$Type] $Message" | Out-File -FilePath $LogFile -Encoding ASCII -Append -ErrorAction SilentlyContinue
}

function Write-OperationLog {
    <#
    .SYNOPSIS
    Enhanced logging for input/output operations with detailed context
    #>
    param(
        [string]$Operation,
        [string]$InputValue = '',
        [string]$OutputPath = '',
        [string]$Context = '',
        [string]$Status = 'SUCCESS',
        [string]$Details = ''
    )
    
    $logMessage = "OPERATION=$Operation | INPUT=$InputValue | OUTPUT=$OutputPath | CONTEXT=$Context | STATUS=$Status | DETAILS=$Details"
    Write-Log $logMessage 'OPERATION'
}

function Invoke-Cleanup {
    <#
    .SYNOPSIS
    Cleanup function called on exit or Ctrl+C
    #>
    if ($script:CleanupExecuted) { return }
    $script:CleanupExecuted = $true
    
    Write-Host "`n[INFO] Performing cleanup..." -ForegroundColor Cyan
    Write-Log "Cleanup: Starting cleanup procedure"
    
    # Save any unsaved changes if needed
    # (currently auto-saves on edit/add, so nothing to do here)
    
    # Ensure run_space directory exists (for consistency with other programs)
    $runSpace = Join-Path $ScriptDir 'run_space'
    if (-not (Test-Path $runSpace)) {
        $null = New-Item -ItemType Directory -Path $runSpace -Force -ErrorAction SilentlyContinue
        Write-Log "Cleanup: Created run_space directory"
    }
    
    # Clean up temp files in run_space if debug mode is enabled
    if ($InternalSettings.debug_mode -and (Test-Path $runSpace)) {
        try {
            Get-ChildItem $runSpace -Filter '*.tmp' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Log "Cleanup: Removed temp files from run_space (debug mode)"
        } catch {
            Write-Log "Cleanup: Failed to clean run_space: $_"
        }
    }
    
    # Dispose file watcher
    if ($script:FileWatcher) {
        try {
            $script:FileWatcher.EnableRaisingEvents = $false
            $script:FileWatcher.Dispose()
            Write-Log "Cleanup: Disposed file watcher"
        } catch {
            Write-Log "Cleanup: Failed to dispose file watcher: $_"
        }
    }
    
    Write-Host "[INFO] Cleanup complete." -ForegroundColor Green
    Write-Log "Cleanup: Cleanup procedure completed"
}

function Test-Timeout {
    <#
    .SYNOPSIS
    Check if execution has exceeded timeout limit
    #>
    if ($InternalSettings.timeout_seconds -le 0) { return $false }
    
    $elapsed = (Get-Date) - $script:StartTime
    if ($elapsed.TotalSeconds -gt $InternalSettings.timeout_seconds) {
        Write-Host "`n========================================" -ForegroundColor Red
        Write-Host "[ERROR] TIMEOUT EXCEEDED" -ForegroundColor Red
        Write-Host "[ERROR] Program ran for $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Red
        Write-Host "[ERROR] Maximum allowed: $($InternalSettings.timeout_seconds) seconds" -ForegroundColor Red
        Write-Host "[ERROR] Exiting to prevent runaway execution" -ForegroundColor Red
        Write-Host "========================================`n" -ForegroundColor Red
        Write-Log "ERROR: Timeout exceeded after $($elapsed.TotalSeconds) seconds (max: $($InternalSettings.timeout_seconds))" 'ERROR'
        return $true
    }
    return $false
}

# Register Ctrl+C handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Invoke-Cleanup
} -ErrorAction SilentlyContinue

# Also handle console Ctrl+C
try {
    [Console]::TreatControlCAsInput = $false
    $null = [Console]::CancelKeyPress.AddHandler({
        param($sender, $e)
        $e.Cancel = $true
        Write-Host "`n`n[WARN] Ctrl+C detected. Exiting gracefully..." -ForegroundColor Yellow
        Invoke-Cleanup
        exit 0
    })
} catch {
    # Console may not be available in all contexts (piped input, non-interactive)
}

function Get-UserInput {
    <#
    .SYNOPSIS
    Safe input reading that handles piped input and null gracefully
    Logs all inputs for debugging
    #>
    param([string]$Prompt)
    
    try {
        $input = Read-Host -Prompt $Prompt
        if ([string]::IsNullOrWhiteSpace($input)) { 
            Write-OperationLog -Operation 'USER_INPUT' -InputValue '<NULL_OR_EMPTY>' -Context $Prompt -Status 'RECEIVED'
            return $null 
        }
        $trimmedInput = $input.Trim()
        # Log the input (mask password fields for security)
        $logValue = if ($Prompt -like '*password*') { '<PASSWORD_MASKED>' } else { $trimmedInput }
        Write-OperationLog -Operation 'USER_INPUT' -InputValue $logValue -Context $Prompt -Status 'RECEIVED'
        return $trimmedInput
    } catch {
        Write-OperationLog -Operation 'USER_INPUT' -InputValue '<ERROR>' -Context $Prompt -Status 'FAILED' -Details $_
        return $null
    }
}

function Load-Settings {
    <#
    .SYNOPSIS
    Loads settings from settings.ini into structured object
    
    .OUTPUTS
    Hashtable with structure: @{ Section = @{ Key = @{ Value=''; Description='' } } }
    #>
    
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
    param([hashtable]$Settings)
    
    <#
    .SYNOPSIS
    Saves settings back to settings.ini with formatting preserved
    Includes detailed write operation logging
    #>
    
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

function Show-AllSettings {
    param([hashtable]$Settings)
    
    <#
    .SYNOPSIS
    Displays all settings in formatted table
    #>
    
    Write-Host "`n========================================================================================================" -ForegroundColor Cyan
    Write-Host " SETTINGS MANAGER" -ForegroundColor Cyan
    Write-Host "========================================================================================================" -ForegroundColor Cyan
    
    foreach ($section in $Settings.Keys | Sort-Object) {
        Write-Host "`n[$section]" -ForegroundColor Yellow
        Write-Host ("{0,-30} {1,-20} {2}" -f "Setting Name", "Value", "Description") -ForegroundColor Gray
        Write-Host ("-" * 100) -ForegroundColor Gray
        
        foreach ($key in $Settings[$section].Keys | Sort-Object) {
            $value = $Settings[$section][$key].Value
            $desc = $Settings[$section][$key].Description
            
            # Truncate long descriptions
            if ($desc.Length -gt 50) {
                $desc = $desc.Substring(0, 47) + "..."
            }
            
            Write-Host ("{0,-30} {1,-20} {2}" -f $key, $value, $desc)
        }
    }
    
    Write-Host "`n========================================================================================================`n" -ForegroundColor Cyan
}

function Edit-Setting {
    param(
        [hashtable]$Settings,
        [string]$FullKey,
        [string]$NewValue
    )
    
    <#
    .SYNOPSIS
    Edits an existing setting value
    .PARAMETER FullKey
    Format: Section.Key (e.g., "General.debug" or "Logging.log_input")
    #>
    
    if ($FullKey -notmatch '^(.+)\.(.+)$') {
        Write-Host "[ERROR] Invalid key format. Use: Section.Key (e.g., General.debug)" -ForegroundColor Red
        Write-OperationLog -Operation 'EDIT_SETTING' -InputValue $FullKey -Status 'FAILED' -Details "Invalid key format"
        return $false
    }
    
    $section = $matches[1]
    $key = $matches[2]
    
    if (-not $Settings.ContainsKey($section)) {
        Write-Host "[ERROR] Section '$section' not found." -ForegroundColor Red
        Write-OperationLog -Operation 'EDIT_SETTING' -InputValue "$section.$key" -Status 'FAILED' -Details "Section not found"
        return $false
    }
    
    if (-not $Settings[$section].ContainsKey($key)) {
        Write-Host "[ERROR] Setting '$key' not found in section '$section'." -ForegroundColor Red
        Write-OperationLog -Operation 'EDIT_SETTING' -InputValue "$section.$key" -Status 'FAILED' -Details "Key not found"
        return $false
    }
    
    $oldValue = $Settings[$section][$key].Value
    $Settings[$section][$key].Value = $NewValue
    
    Write-Host "[INFO] Updated $FullKey from '$oldValue' to '$NewValue'" -ForegroundColor Green
    Write-OperationLog -Operation 'EDIT_SETTING' -InputValue $NewValue -Context "$section.$key" -Status 'SUCCESS' -Details "Changed from: $oldValue"
    Write-Log "Updated $FullKey from '$oldValue' to '$NewValue'"
    
    return $true
}

function Add-Setting {
    param(
        [hashtable]$Settings,
        [string]$Section,
        [string]$Key,
        [string]$Value,
        [string]$Description
    )
    
    <#
    .SYNOPSIS
    Adds a new setting to specified section
    #>
    
    # Validate section if enabled (allow custom sections by creating them)
    if ($InternalSettings.validate_sections -and $Section -notin $InternalSettings.allowed_sections) {
        $allowedList = $InternalSettings.allowed_sections -join ', '
        Write-Host "[INFO] Section '$Section' is not in standard list ($allowedList)" -ForegroundColor Cyan
        Write-Host "[INFO] Creating custom section: $Section" -ForegroundColor Cyan
        Write-OperationLog -Operation 'ADD_SETTING' -InputValue "$Section.$Key" -Status 'NOTICE' -Details "Creating custom section: $Section"
    }
    
    if (-not $Settings.ContainsKey($Section)) {
        $Settings[$Section] = @{}
        Write-Host "[INFO] Created new section: $Section" -ForegroundColor Cyan
        Write-OperationLog -Operation 'ADD_SETTING' -Context $Section -Status 'SECTION_CREATED'
    }
    
    if ($Settings[$Section].ContainsKey($Key)) {
        Write-Host "[WARN] Setting '$Key' already exists in '$Section'. Use edit to modify." -ForegroundColor Yellow
        Write-OperationLog -Operation 'ADD_SETTING' -InputValue "$Section.$Key" -Status 'FAILED' -Details "Key already exists"
        return $false
    }
    
    $Settings[$Section][$Key] = @{
        Value = $Value
        Description = $Description
    }
    
    Write-Host "[INFO] Added new setting: $Section.$Key = $Value" -ForegroundColor Green
    Write-OperationLog -Operation 'ADD_SETTING' -InputValue $Value -Context "$Section.$Key" -Status 'SUCCESS' -Details "Description: $Description"
    Write-Log "Added new setting: $Section.$Key = $Value"
    
    return $true
}

function Initialize-FileWatcher {
    <#
    .SYNOPSIS
    Sets up FileSystemWatcher to monitor settings.ini for external changes
    #>
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
    if (Test-Path $SettingsFile) {
        $script:LastModifiedTime = (Get-Item $SettingsFile).LastWriteTime
    }
}

function Show-Menu {
    # Check if settings file was modified externally
    if (Test-SettingsFileChanged) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "  EXTERNAL CHANGE DETECTED" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "[ALERT] settings.ini was modified externally" -ForegroundColor Yellow
        Write-Host "[INFO] Auto-reloading settings from file..." -ForegroundColor Cyan
        try {
            $global:settings = Load-Settings
            Update-LastModifiedTime
            Write-Host "[INFO] Settings reloaded successfully!" -ForegroundColor Green
            Write-Log "Auto-reloaded settings due to external file change"
        } catch {
            Write-Host "[ERROR] Failed to reload: $_" -ForegroundColor Red
            Write-Log "ERROR: Auto-reload failed: $_" 'ERROR'
        }
        Write-Host "========================================" -ForegroundColor Yellow
    }
    
    Write-Host "`n========== SETTINGS MANAGER MENU ==========" -ForegroundColor Cyan
    Write-Host "[1] View all settings"
    Write-Host "[2] Edit a setting"
    Write-Host "[3] Add new setting"
    Write-Host "[4] Reload settings from file"
    Write-Host "[5] Save settings to file"
    if ($InternalSettings.debug_mode) {
        Write-Host "[6] Run test program (DEBUG)" -ForegroundColor Magenta
        Write-Host "[7] Edit internal config (DEBUG)" -ForegroundColor Magenta
        Write-Host "[8] Quit"
    } else {
        Write-Host "[6] Enable Debug Mode" -ForegroundColor Yellow
        Write-Host "[7] Quit"
    }
    Write-Host "=" -ForegroundColor Cyan
}

# Main execution
Write-Host "`n[INFO] Settings Manager starting..." -ForegroundColor Cyan
Write-Log "Settings Manager started"

# Auto-generate README.md on first run
$ReadmeFile = Join-Path $ScriptDir 'README.md'
if (-not (Test-Path $ReadmeFile) -and $InternalSettings.auto_generate_readme) {
    Write-Host "[INFO] Generating README.md..." -ForegroundColor Cyan
    $readmeContent = @"
# Settings Manager

## Purpose
Settings Manager is a PowerShell-based configuration editor for managing settings.ini files used by other programs in the cmd workspace.

## Features
- View all settings in formatted tables
- Edit existing settings (name, value, description)
- Add new settings with section support
- Auto-save with validation
- Debug mode with internal configuration editor
- Test program integration
- Comprehensive logging system

## Usage
Double-click ``run.bat`` or run from terminal:
````batch
run.bat
````

### Menu Options
1. **View all settings** - Display all sections and settings
2. **Edit a setting** - Modify existing setting values or properties
3. **Add new setting** - Create new settings in any section
4. **Reload settings** - Refresh from settings.ini
5. **Save settings** - Write changes to file
6. **Debug Mode** - Enable advanced features (requires password)
7. **Quit** - Exit the program

### Debug Mode (password: admin)
When debug mode is enabled:
- **[6] Run test program** - Execute test_print_program.ps1
- **[7] Edit internal config** - Modify Settings Manager's own settings
- **[8] Quit** - Exit the program

## Structure
````
settings/
├── run.bat              # Main executable
├── Manage-Settings.ps1  # PowerShell implementation
├── settings.ini         # Configuration file (managed)
├── .internal_config     # Internal settings
├── README.md            # This file
└── _debug/
    ├── logs/
    │   └── important.log  # Operation log
    ├── test_print_program.ps1  # Test program
    ├── run_test.bat     # Test launcher
    └── automated_testing_environment/  # Testing workspace
````

## Settings File Format
````ini
[Section]
key=value  # Description
````

## Logging
All operations are logged to ``_debug/logs/important.log`` with timestamps and full context.

## Testing
Run automated tests from ``_debug/automated_testing_environment/``:
````powershell
cd _debug/automated_testing_environment
.\run.bat
````

## Exit Codes
- **0**: Success
- **1**: Error or timeout
"@
    $readmeContent | Out-File -FilePath $ReadmeFile -Encoding UTF8 -Force
    Write-Host "[INFO] README.md generated successfully." -ForegroundColor Green
    Write-Log "Generated README.md on first run"
}

# Create empty settings.ini if it doesn't exist (it's for other programs to populate)
if (-not (Test-Path $SettingsFile)) {
    Write-Host "[INFO] Creating empty settings.ini..." -ForegroundColor Cyan
    $emptySettings = @"
# Settings Configuration File
# Format: key=value  # Description
# This file is managed by Settings Manager and used by other programs

"@
    $emptySettings | Out-File -FilePath $SettingsFile -Encoding UTF8 -Force
    Write-Host "[INFO] Created empty settings.ini. Use 'Add new setting' to configure programs." -ForegroundColor Green
    Write-Log "Created empty settings.ini"
}

$settings = Load-Settings

# Initialize file watcher for external changes
Initialize-FileWatcher

# Empty settings file is valid - this is just an editor for other programs
if ($settings.Count -eq 0) {
    Write-Host "[INFO] Settings file is empty. Use 'Add new setting' to begin." -ForegroundColor Cyan
} else {
    $totalSettings = ($settings.Values | ForEach-Object { $_.Keys.Count } | Measure-Object -Sum).Sum
    Write-Host "[INFO] Loaded $($settings.Keys.Count) section(s) with $totalSettings setting(s)." -ForegroundColor Cyan
}

# Wrap entire main loop in try-catch to prevent any unhandled errors
try {
    while ($true) {
        # Check timeout
        if (Test-Timeout) {
            Invoke-Cleanup
            exit 1
        }
        
        Show-Menu
        
        $choice = Get-UserInput "`nEnter choice"
        if ($null -eq $choice) {
            Write-Host "[INFO] Exiting Settings Manager." -ForegroundColor Cyan
            Write-Log "Settings Manager exited (empty input or pipe exhausted)"
            Invoke-Cleanup
            break
        }
        
        Write-Log "User input: $choice"
        
        switch ($choice.ToUpper()) {
            '1' {
                try {
                    Show-AllSettings -Settings $settings
                } catch {
                    Write-Host "[ERROR] Failed to display settings: $_" -ForegroundColor Red
                    Write-Log "ERROR displaying settings: $_"
                }
            }
            '2' {
                try {
                    if ($settings.Count -eq 0) {
                        Write-Host "[WARN] No settings available to edit." -ForegroundColor Yellow
                        continue
                    }

                    $choices = @()
                    $idx = 1
                    Write-Host "`nSelect a setting to edit (type the number):" -ForegroundColor Gray
                    foreach ($section in $settings.Keys | Sort-Object) {
                        foreach ($key in $settings[$section].Keys | Sort-Object) {
                            $value = $settings[$section][$key].Value
                            $choices += @{ Index = $idx; Section = $section; Key = $key }
                            Write-Host ("[{0}] {1}.{2} = {3}" -f $idx, $section, $key, $value)
                            $idx++
                        }
                    }

                    $selection = Get-UserInput "Enter number (or Q to cancel)"
                    if ($null -eq $selection -or $selection.ToUpper() -eq 'Q') {
                        Write-Host "[INFO] Edit cancelled." -ForegroundColor Yellow
                        continue
                    }

                    $selectionInt = 0
                    if (-not [int]::TryParse($selection, [ref]$selectionInt)) {
                        Write-Host "[ERROR] Please enter a valid number." -ForegroundColor Red
                        continue
                    }

                    $selected = $choices | Where-Object { $_.Index -eq $selectionInt }
                    if (-not $selected) {
                        Write-Host "[ERROR] Invalid selection." -ForegroundColor Red
                        continue
                    }

                    # In debug mode, allow editing key name, value, or description
                    if ($InternalSettings.debug_mode) {
                        $currentKey = $selected.Key
                        $currentValue = $settings[$selected.Section][$currentKey].Value
                        $currentDesc = $settings[$selected.Section][$currentKey].Description
                        
                        Write-Host "`nWhat would you like to edit?" -ForegroundColor Cyan
                        Write-Host "[1] Key name (currently: $currentKey)"
                        Write-Host "[2] Value (currently: $currentValue)"
                        Write-Host "[3] Description (currently: $currentDesc)"
                        Write-Host "[Q] Cancel"
                        
                        $editChoice = Get-UserInput "Enter choice"
                        if ($null -eq $editChoice -or $editChoice.ToUpper() -eq 'Q') {
                            Write-Host "[INFO] Edit cancelled." -ForegroundColor Yellow
                            continue
                        }
                        
                        switch ($editChoice) {
                            '1' {
                                $newKey = Get-UserInput "Enter new key name"
                                if ($null -eq $newKey) {
                                    Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                                    continue
                                }
                                
                                if ($settings[$selected.Section].ContainsKey($newKey)) {
                                    Write-Host "[ERROR] Key '$newKey' already exists in section '$($selected.Section)'." -ForegroundColor Red
                                    continue
                                }
                                
                                # Rename key by copying and removing old
                                $settings[$selected.Section][$newKey] = $settings[$selected.Section][$currentKey]
                                $settings[$selected.Section].Remove($currentKey)
                                Write-Host "[INFO] Renamed key from '$currentKey' to '$newKey'" -ForegroundColor Green
                                Write-Log "Renamed setting key: $($selected.Section).$currentKey -> $newKey"
                                Save-Settings -Settings $settings
                            }
                            '2' {
                                $newValue = Get-UserInput "Enter new value"
                                if ($null -eq $newValue) {
                                    Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                                    continue
                                }
                                
                                $settings[$selected.Section][$currentKey].Value = $newValue
                                Write-Host "[INFO] Updated value to '$newValue'" -ForegroundColor Green
                                Write-Log "Updated setting value: $($selected.Section).$currentKey = $newValue"
                                Save-Settings -Settings $settings
                            }
                            '3' {
                                $newDesc = Get-UserInput "Enter new description"
                                if ($null -eq $newDesc) {
                                    Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                                    continue
                                }
                                
                                $settings[$selected.Section][$currentKey].Description = $newDesc
                                Write-Host "[INFO] Updated description to '$newDesc'" -ForegroundColor Green
                                Write-Log "Updated setting description: $($selected.Section).$currentKey"
                                Save-Settings -Settings $settings
                            }
                            default {
                                Write-Host "[WARN] Invalid choice." -ForegroundColor Yellow
                            }
                        }
                    } else {
                        # Normal mode: only edit value
                        $fullKey = "$($selected.Section).$($selected.Key)"
                        $newValue = Get-UserInput "Enter new value for $fullKey"
                        if ($null -eq $newValue) {
                            Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                            continue
                        }

                        if (Edit-Setting -Settings $settings -FullKey $fullKey -NewValue $newValue) {
                            Save-Settings -Settings $settings
                        }
                    }
                } catch {
                    Write-Host "[ERROR] Failed to edit setting: $_" -ForegroundColor Red
                    Write-Log "ERROR editing setting: $_"
                }
            }
            '3' {
                try {
                    $allowedList = $InternalSettings.allowed_sections -join '/'
                    $section = Get-UserInput "Enter section name ($allowedList or custom)"
                    if ($null -eq $section) {
                        Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                        continue
                    }
                    
                    $key = Get-UserInput "Enter setting key"
                    if ($null -eq $key) {
                        Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                        continue
                    }
                    
                    $value = Get-UserInput "Enter value"
                    if ($null -eq $value) {
                        Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                        continue
                    }
                    
                    $desc = Get-UserInput "Enter description"
                    if ($null -eq $desc) {
                        Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                        continue
                    }
                    
                    if (Add-Setting -Settings $settings -Section $section -Key $key -Value $value -Description $desc) {
                        Save-Settings -Settings $settings
                    }
                } catch {
                    Write-Host "[ERROR] Failed to add setting: $_" -ForegroundColor Red
                    Write-Log "ERROR adding setting: $_"
                }
            }
            '4' {
                try {
                    $settings = Load-Settings
                    Write-Host "[INFO] Settings reloaded from file." -ForegroundColor Green
                } catch {
                    Write-Host "[ERROR] Failed to reload settings: $_" -ForegroundColor Red
                    Write-Log "ERROR reloading settings: $_"
                }
            }
            '5' {
                try {
                    Save-Settings -Settings $settings
                } catch {
                    Write-Host "[ERROR] Failed to save settings: $_" -ForegroundColor Red
                    Write-Log "ERROR saving settings: $_"
                }
            }
            '6' {
                if ($InternalSettings.debug_mode) {
                    try {
                        # Check if required settings exist before running test program
                        $hasRequiredSettings = $false
                        if ($settings.ContainsKey('General') -and $settings['General'].ContainsKey('printVal')) {
                            $hasRequiredSettings = $true
                        }
                        
                        if (-not $hasRequiredSettings) {
                            Write-Host ""
                            Write-Host "========================================" -ForegroundColor Yellow
                            Write-Host "  TEST PROGRAM REQUIRES SETTINGS" -ForegroundColor Yellow
                            Write-Host "========================================" -ForegroundColor Yellow
                            Write-Host ""
                            Write-Host "The test program needs the following setting:" -ForegroundColor White
                            Write-Host ""
                            Write-Host "  * printVal (in General section)" -ForegroundColor Cyan
                            Write-Host "    Description: Text value to print" -ForegroundColor Gray
                            Write-Host ""
                            Write-Host "To add this setting:" -ForegroundColor White
                            Write-Host ""
                            Write-Host "  1. Select [3] Add new setting" -ForegroundColor Green
                            Write-Host "  2. Section: General" -ForegroundColor Green
                            Write-Host "  3. Key: printVal" -ForegroundColor Green
                            Write-Host "  4. Value: Hello from test program!" -ForegroundColor Green
                            Write-Host "  5. Description: Text to print in test" -ForegroundColor Green
                            Write-Host ""
                            Write-Host "Optional: printAmount (integer, defaults to 1)" -ForegroundColor Yellow
                            Write-Host ""
                            Write-Host "========================================" -ForegroundColor Yellow
                            Write-Host ""
                            Write-Log "DEBUG: Test program aborted - missing required settings"
                            continue
                        }
                        
                        $testScript = Join-Path $ScriptDir '_debug\run_test.bat'
                        if (Test-Path $testScript) {
                            Write-Host "`n[DEBUG] Running test program..." -ForegroundColor Magenta
                            Write-Log "DEBUG: Running test program"
                            & cmd /c $testScript
                            Write-Host "`n[DEBUG] Test program finished.`n" -ForegroundColor Magenta
                        } else {
                            Write-Host "[ERROR] Test program not found at: $testScript" -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "[ERROR] Failed to run test program: $_" -ForegroundColor Red
                        Write-Log "ERROR running test program: $_"
                    }
                } else {
                    # Option 6 when debug is off: Enable Debug Mode
                    if (-not $InternalSettings.debug_mode) {
                        try {
                            Write-Host "`n[INFO] Debug mode requires admin password." -ForegroundColor Yellow
                            $password = Get-UserInput "Enter admin password"
                            
                            if ($null -eq $password) {
                                Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                                continue
                            }
                            
                            if ($password -ne $InternalSettings['admin_password']) {
                                Write-Host "[ERROR] Incorrect password. Debug mode not enabled." -ForegroundColor Red
                                Write-Log "WARN: Failed debug mode activation (incorrect password)"
                                continue
                            }
                            
                            $InternalSettings.debug_mode = $true
                            Write-Host "[INFO] Debug mode enabled!" -ForegroundColor Green
                            Write-Log "DEBUG: Debug mode enabled by user"
                            
                            # Update .internal_config file
                            if (Test-Path $InternalConfig) {
                                $configLines = Get-Content $InternalConfig -ErrorAction Stop
                                $newConfigLines = @()
                                foreach ($line in $configLines) {
                                    if ($line -match "^debug_mode\s*=") {
                                        $newConfigLines += "debug_mode=true  # Enable debug features"
                                    } else {
                                        $newConfigLines += $line
                                    }
                                }
                                $newConfigLines | Out-File -FilePath $InternalConfig -Encoding UTF8 -Force
                                Write-Host "[INFO] Debug mode saved to .internal_config" -ForegroundColor Green
                            }
                        } catch {
                            Write-Host "[ERROR] Failed to enable debug mode: $_" -ForegroundColor Red
                            Write-Log "ERROR enabling debug mode: $_"
                        }
                    }
                }
            }
            '7' {
                if ($InternalSettings.debug_mode) {
                    try {
                        Write-Host "`n========================================" -ForegroundColor Magenta
                        Write-Host " INTERNAL CONFIGURATION EDITOR (DEBUG)" -ForegroundColor Magenta
                        Write-Host "========================================`n" -ForegroundColor Magenta
                        
                        # Display current internal settings
                        Write-Host "Current Internal Settings:" -ForegroundColor Cyan
                        foreach ($key in $InternalSettings.Keys | Sort-Object) {
                            $value = $InternalSettings[$key]
                            if ($value -is [array]) {
                                $value = $value -join ', '
                            }
                            Write-Host "  $key = $value" -ForegroundColor Gray
                        }
                        
                        Write-Host "`nAvailable settings to edit:" -ForegroundColor Yellow
                        Write-Host "  [1] debug_mode (true/false)" -ForegroundColor Gray
                        Write-Host "  [2] log_changes (true/false)" -ForegroundColor Gray
                        Write-Host "  [3] validate_sections (true/false)" -ForegroundColor Gray
                        Write-Host "  [4] backup_on_save (true/false)" -ForegroundColor Gray
                        Write-Host "  [5] auto_generate_readme (true/false)" -ForegroundColor Gray
                        Write-Host "  [6] timeout_seconds (number)" -ForegroundColor Gray
                        Write-Host "  [7] admin_password (text)" -ForegroundColor Gray
                        Write-Host "  [Q] Cancel" -ForegroundColor Gray
                        
                        $internalChoice = Get-UserInput "`nSelect setting to edit"
                        if ($null -eq $internalChoice -or $internalChoice.ToUpper() -eq 'Q') {
                            Write-Host "[INFO] Edit cancelled." -ForegroundColor Yellow
                            continue
                        }
                        
                        $settingKey = switch ($internalChoice) {
                            '1' { 'debug_mode' }
                            '2' { 'log_changes' }
                            '3' { 'validate_sections' }
                            '4' { 'backup_on_save' }
                            '5' { 'auto_generate_readme' }
                            '6' { 'timeout_seconds' }
                            '7' { 'admin_password' }
                            default { $null }
                        }
                        
                        if (-not $settingKey) {
                            Write-Host "[ERROR] Invalid selection." -ForegroundColor Red
                            continue
                        }
                        
                        # For admin_password, require verification of current password first
                        if ($settingKey -eq 'admin_password') {
                            $currentPassword = Get-UserInput "Enter current admin password"
                            if ($null -eq $currentPassword) {
                                Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                                continue
                            }
                            
                            if ($currentPassword -ne $InternalSettings['admin_password']) {
                                Write-Host "[ERROR] Incorrect password. Cannot change admin password." -ForegroundColor Red
                                Write-Log "WARN: Failed admin password change attempt (incorrect current password)"
                                continue
                            }
                        }
                        
                        $newValue = Get-UserInput "Enter new value for $settingKey"
                        if ($null -eq $newValue) {
                            Write-Host "[WARN] Operation cancelled." -ForegroundColor Yellow
                            continue
                        }
                        
                        # Validate based on setting type
                        if ($settingKey -eq 'timeout_seconds') {
                            $numValue = 0
                            if (-not [int]::TryParse($newValue, [ref]$numValue) -or $numValue -lt 0) {
                                Write-Host "[ERROR] timeout_seconds must be a positive number (0 to disable)" -ForegroundColor Red
                                continue
                            }
                        } elseif ($settingKey -eq 'admin_password') {
                            # Validate password - cannot be empty
                            if ([string]::IsNullOrWhiteSpace($newValue)) {
                                Write-Host "[ERROR] Password cannot be empty" -ForegroundColor Red
                                continue
                            }
                        } elseif ($newValue -inotin @('true', 'false')) {
                            Write-Host "[ERROR] Value must be 'true' or 'false'" -ForegroundColor Red
                            continue
                        }
                        
                        # Update in memory
                        $oldValue = $InternalSettings[$settingKey]
                        if ($settingKey -eq 'timeout_seconds') {
                            $InternalSettings[$settingKey] = [int]$newValue
                        } elseif ($settingKey -eq 'admin_password') {
                            $InternalSettings[$settingKey] = $newValue
                        } else {
                            $InternalSettings[$settingKey] = ($newValue -ieq 'true')
                        }
                        
                        # Save to .internal_config (create if missing)
                        if (-not (Test-Path $InternalConfig)) {
                            Write-Host "[WARN] .internal_config missing, creating new one..." -ForegroundColor Yellow
                            $defaultConfig = @"
# Settings Manager Internal Configuration
# This file controls the Settings Manager program itself

[Internal]
auto_generate_readme=true  # Automatically generate README.md on first run
log_changes=true  # Log all setting modifications to important.log
backup_on_save=false  # Create backup before saving settings
validate_sections=true  # Validate section names against allowed list
allowed_sections=General,Logging,Advanced  # Comma-separated list of valid section names
debug_mode=false  # Enable debug menu options (run test program)
timeout_seconds=300  # Execution timeout in seconds (0 to disable)
admin_password=admin  # Password required to enable debug mode
"@
                            $defaultConfig | Out-File -FilePath $InternalConfig -Encoding UTF8 -Force
                        }
                        
                        $configLines = Get-Content $InternalConfig -ErrorAction Stop
                        $newConfigLines = @()
                        $updated = $false
                        
                        foreach ($line in $configLines) {
                            if ($line -match "^$settingKey\s*=") {
                                $newConfigLines += "$settingKey=$newValue  # " + ($line -split '#',2)[1].Trim()
                                $updated = $true
                            } else {
                                $newConfigLines += $line
                            }
                        }
                        
                        $newConfigLines | Out-File -FilePath $InternalConfig -Encoding UTF8 -Force
                        
                        Write-Host "[INFO] Updated $settingKey from '$oldValue' to '$newValue'" -ForegroundColor Green
                        Write-Host "[INFO] Internal config saved to .internal_config" -ForegroundColor Green
                        Write-Log "DEBUG: Updated internal setting $settingKey from '$oldValue' to '$newValue'"
                        
                    } catch {
                        Write-Host "[ERROR] Failed to edit internal config: $_" -ForegroundColor Red
                        Write-Log "ERROR editing internal config: $_"
                    }
                } else {
                    # When debug mode is off, option 7 is Quit
                    Write-Host "[INFO] Exiting Settings Manager." -ForegroundColor Cyan
                    Write-Log "Settings Manager exited normally"
                    Invoke-Cleanup
                    exit 0
                }
            }
            '8' {
                # Option 8 is only available when debug mode is on - Quit
                Write-Host "[INFO] Exiting Settings Manager." -ForegroundColor Cyan
                Write-Log "Settings Manager exited normally"
                Invoke-Cleanup
                exit 0
            }
            default {
                Write-Host "[WARN] Invalid choice. Please try again." -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "[ERROR] Unexpected error: $_" -ForegroundColor Red
    Write-Log "FATAL ERROR: $_"
    Invoke-Cleanup
    exit 1
}

Invoke-Cleanup
exit 0
