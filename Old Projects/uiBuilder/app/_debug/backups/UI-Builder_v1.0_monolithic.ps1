#Requires -Version 5.0

<#
.SYNOPSIS
uiBuilder - PowerShell General UI Menu Builder
A hierarchical menu system for building interactive user interfaces compatible with multiple programs.

.DESCRIPTION
Creates numbered or interactive menus from a CSV button list with submenu support, 
piped input handling, and multi-language code stub generation.

.PARAMETER --debug
Enable debug mode with UI state logging

.PARAMETER --debug-menu <path>
Jump directly to specific menu path (e.g., mainUI.settings)

.PARAMETER --debug-select <index>
Simulate selecting option at index N

.PARAMETER --debug-key <key>
Simulate key press (Up, Down, Enter, Escape, Shift)

.PARAMETER add <name> <description> <path> <type>
Add new button to menu

.PARAMETER remove <path>
Remove button by path

.PARAMETER list
List all buttons

.PARAMETER --generate-stub <language>
Generate code stub for language (ps1, bat, py, cs)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# SCRIPT INITIALIZATION
# ============================================================================

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:buttonListPath = Join-Path $script:scriptDir "button.list"
$script:settingsPath = Join-Path $script:scriptDir "settings.ini"
$script:debugPath = Join-Path $script:scriptDir "_debug"
$script:logsPath = Join-Path $script:debugPath "logs"
$script:runSpacePath = Join-Path $script:scriptDir "run_space"
$script:transcriptPath = Join-Path $script:logsPath "ui-transcript.log"

# Ensure directories exist
@($script:logsPath, $script:runSpacePath) | ForEach-Object { 
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

$script:buttonIndex = @{}
$script:settings = @{}
$script:debugMode = $false
$script:debugMenuPath = $null
$script:debugSelectIndex = $null
$script:currentPath = "mainUI"
$script:breadcrumb = @("mainUI")
$script:keepOpenAfterSelection = $true
$script:autoClose = $false
$script:debugSequenceIndex = $null
$script:debugKeySequence = @()

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Get-Timestamp {
    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Log-Navigation {
    param([string]$Message)
    if (-not $script:settings.Logging.log_navigation) { return }
    $logFile = Join-Path $script:logsPath "navigation.log"
    "[$(Get-Timestamp)] NAVIGATE: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Input {
    param([string]$Message)
    if (-not $script:settings.Logging.log_input) { return }
    $logFile = Join-Path $script:logsPath "input.log"
    "[$(Get-Timestamp)] INPUT: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Error {
    param([string]$Message)
    if (-not $script:settings.Logging.log_error) { return }
    $logFile = Join-Path $script:logsPath "error.log"
    "[$(Get-Timestamp)] ERROR: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Important {
    param([string]$Message)
    if (-not $script:settings.Logging.log_important) { return }
    $logFile = Join-Path $script:logsPath "important.log"
    "[$(Get-Timestamp)] INFO: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Debug {
    param([string]$Message)
    if (-not $script:debugMode) { return }
    $logFile = Join-Path $script:logsPath "ui-debug.log"
    "[$(Get-Timestamp)] DEBUG: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Write-Transcript {
    param([string]$Message)
    if (-not $script:settings.Logging.log_transcript) { return }
    $Message | Add-Content -Path $script:transcriptPath -Encoding UTF8
}

# ============================================================================
# CSV I/O FUNCTIONS
# ============================================================================

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
    
    $csv = "Name,Description,Path,Type`n"
    foreach ($button in $Buttons) {
        $csv += "`"$($button.Name)`",`"$($button.Description)`",$($button.Path),$($button.Type)`n"
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

# ============================================================================
# SETTINGS I/O FUNCTIONS
# ============================================================================

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

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

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

# ============================================================================
# BUTTON MANAGEMENT FUNCTIONS
# ============================================================================

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

# ============================================================================
# DEBUG SLOW MODE - Simulates key presses for testing
# ============================================================================

function Get-DebugSlowModeKey {
    <#
    .DESCRIPTION
    In debug slow mode, returns simulated key events instead of reading from console.
    Allows testing with arrows, backspace, shift, and q keys.
    #>
    
    # For debug slow mode, we cycle through predefined test sequences
    # Initialize on first call
    if ($null -eq $script:debugSequenceIndex) {
        $script:debugSequenceIndex = 0
        # Test sequence: Navigate with arrows, test shift color, show description, navigate directories
        $script:debugKeySequence = @(
            @{ VirtualKeyCode = 40; Character = [char]0; ControlKeyState = 0 },     # Down arrow
            @{ VirtualKeyCode = 40; Character = [char]0; ControlKeyState = 0 },     # Down arrow
            @{ VirtualKeyCode = 40; Character = [char]0; ControlKeyState = 0 },     # Down arrow
            @{ VirtualKeyCode = 38; Character = [char]0; ControlKeyState = 0 },     # Up arrow
            @{ VirtualKeyCode = 13; Character = [char]0; ControlKeyState = 0x0010 }, # Shift+Enter show desc
            @{ VirtualKeyCode = 13; Character = [char]0; ControlKeyState = 0 },     # Enter (go into submenu)
            @{ VirtualKeyCode = 40; Character = [char]0; ControlKeyState = 0 },     # Down arrow
            @{ VirtualKeyCode = 13; Character = [char]0; ControlKeyState = 0 },     # Enter (select item)
            @{ VirtualKeyCode = 8; Character = [char]0; ControlKeyState = 0 },      # Backspace (go back)
            @{ VirtualKeyCode = 40; Character = [char]0; ControlKeyState = 0 },     # Down arrow
            @{ VirtualKeyCode = 13; Character = [char]0; ControlKeyState = 0 }      # Enter to select
        )
        Write-Host "[DEBUG] Slow mode enabled - testing arrow navigation, shift colors, and directory navigation..." -ForegroundColor Magenta
    }
    
    if ($script:debugSequenceIndex -lt $script:debugKeySequence.Count) {
        $key = $script:debugKeySequence[$script:debugSequenceIndex]
        $script:debugSequenceIndex++
        
        # Log the simulated key press
        $keyName = switch ($key.VirtualKeyCode) {
            40 { "DOWN" }
            38 { "UP" }
            8  { "BACKSPACE" }
            13 { "ENTER" }
            81 { "Q" }
            default { "KEY($($key.VirtualKeyCode))" }
        }
        $shift = if ($key.ControlKeyState -band 0x0010) { "+SHIFT" } else { "" }
        Write-Host "[DEBUG] Simulated key: $keyName$shift" -ForegroundColor Cyan
        
        Start-Sleep -Milliseconds 800  # Slow down for visual inspection
        return $key
    } else {
        # Sequence completed, auto-quit to prevent hanging
        Write-Host "[DEBUG] Sequence complete - auto-quitting to prevent input wait" -ForegroundColor Magenta
        # Return Q key to quit gracefully
        return @{ VirtualKeyCode = 81; Character = 'q'; ControlKeyState = 0 }  # 81 = Q
    }
}

# ============================================================================
# UI DISPLAY FUNCTIONS
# ============================================================================

function Show-NumberedMenu {
    param(
        [array]$Items,
        [string]$HighlightColor = 'Green',
        [string]$ShiftColor = 'Yellow'
    )
    
    if ($Items.Count -eq 0) {
        Write-Host "No items available" -ForegroundColor Red
        return @{ Action = 'back'; Index = -1 }
    }
    
    Log-Debug "Menu with $($Items.Count) items"
    
    while ($true) {
        if (-not [Console]::IsInputRedirected) { Clear-Host }
        
        # Numbered mode: White text only for fast debugging
        $displayLines = @("================================", "SELECT OPTION:", "================================")
        Write-Host "================================" -ForegroundColor White
        Write-Host "SELECT OPTION:" -ForegroundColor White
        Write-Host "================================" -ForegroundColor White
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $line = Format-MenuItem -Item $Items[$i] -Index $i
            $displayLines += $line
            Write-Host $line -ForegroundColor White
        }
        
        $displayLines += "", "* = Action  |  [ ] = Submenu", "0 = Back  |  q/Q = Quit", ""
        Write-Host ""
        Write-Host "* = Action  |  [ ] = Submenu" -ForegroundColor White
        Write-Host "0 = Back  |  q/Q = Quit" -ForegroundColor White
        Write-Host ""
        Write-Transcript ($displayLines -join "`n")
        
        try {
            # In debug slow mode, never prompt for input - it should use Get-DebugSlowModeKey instead
            if ($script:debugSlowMode) {
                Log-Input "Debug mode: numbered menu should not be reached"
                return @{ Action = 'quit'; Index = -1 }
            }
            $userInput = if ([Console]::IsInputRedirected) {
                [Console]::In.ReadLine()
            } else {
                Read-Host "Enter number"
            }
        }
        catch {
            Log-Input "EOF"
            return @{ Action = 'quit'; Index = -1 }
        }
        
        if ($null -eq $userInput) {
            Log-Input "Empty"
            return @{ Action = 'quit'; Index = -1 }
        }
        
        $userInput = $userInput.Trim().ToLower()
        Log-Input $userInput
        Write-Transcript "INPUT: $userInput"
        
        switch ($userInput) {
            'q' { return @{ Action = 'quit'; Index = -1 } }
            '0' { return @{ Action = 'back'; Index = -1 } }
            default {
                if ($userInput -match '^\d+$') {
                    $index = [int]$userInput - 1
                    if ($index -ge 0 -and $index -lt $Items.Count) {
                        Log-Input "Selected: $index"
                        return @{ Action = 'select'; Index = $index }
                    }
                }
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Milliseconds 500
            }
        }
    }
}

function Show-DescriptionBox {
    param(
        [string]$Description,
        [string]$ItemName
    )
    
    Clear-Host
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "DESCRIPTION: $ItemName" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Description)) {
        Write-Host "No description available" -ForegroundColor Gray
    } else {
        Write-Host $Description -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Press any key to continue..." -ForegroundColor Green
    
    # Wait for actual keypress (ignore modifier key releases)
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } while ($key.VirtualKeyCode -eq 16 -or $key.VirtualKeyCode -eq 17 -or $key.VirtualKeyCode -eq 18)  # Ignore shift, ctrl, alt
}

# Helper: Format a single menu item for display
function Format-MenuItem {
    param(
        [object]$Item,
        [int]$Index,
        [string]$Prefix = "   "
    )
    
    $displayIndex = $Index + 1
    $itemType = $Item['Type']
    if ([string]::IsNullOrWhiteSpace($itemType)) { $itemType = 'option' }
    
    # Get value if it exists and is not empty
    $itemValue = $Item['Value']
    $valueStr = ""
    if (-not [string]::IsNullOrWhiteSpace($itemValue)) {
        $valueStr = " {: $itemValue}"
    }
    
    if ($itemType -eq 'submenu') {
        return "$prefix$displayIndex. [$($Item['Name'])]$valueStr"
    } else {
        return "$prefix$displayIndex. *$($Item['Name'])$valueStr"
    }
}

function Show-InteractiveMenu {
    param(
        [array]$Items,
        [string]$HighlightColor = 'Green',
        [string]$ArrowColor = 'Cyan',
        [string]$ShiftColor = 'Yellow'
    )
    
    if ($Items.Count -eq 0) {
        Write-Host "No items available" -ForegroundColor Red
        return @{ Action = 'back'; Index = -1 }
    }
    
    # Fall back to numbered menu if piped (unless in debug_slow_mode)
    if ([Console]::IsInputRedirected -and -not $script:debugSlowMode) {
        return Show-NumberedMenu -Items $Items -HighlightColor $HighlightColor
    }
    
    $selectedIndex = 0
    $isShiftCurrentlyHeld = $false
    
    while ($true) {
        Clear-Host
        $displayLines = @("================================", "SELECT OPTION (use arrow keys):", "================================")
        Write-Host "================================" -ForegroundColor $ArrowColor
        Write-Host "SELECT OPTION (use arrow keys):" -ForegroundColor $ArrowColor
        Write-Host "================================" -ForegroundColor $ArrowColor
        Write-Host ""
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $prefix = if ($i -eq $selectedIndex) { ">> " } else { "   " }
            # Change color to shift color if shift is held and this is the selected item
            $color = if ($i -eq $selectedIndex) { 
                if ($isShiftCurrentlyHeld) { $ShiftColor } else { $HighlightColor }
            } else { "White" }
            # Interactive mode: NO numbers, just prefix and name
            $itemType = $Items[$i]['Type']
            if ([string]::IsNullOrWhiteSpace($itemType)) { $itemType = 'option' }
            $itemValue = $Items[$i]['Value']
            $valueStr = ""
            if (-not [string]::IsNullOrWhiteSpace($itemValue)) {
                $valueStr = " {: $itemValue}"
            }
            if ($itemType -eq 'submenu') {
                $line = "$prefix[$($Items[$i]['Name'])]$valueStr"
            } else {
                $line = "$prefix*$($Items[$i]['Name'])$valueStr"
            }
            $displayLines += $line
            Write-Host $line -ForegroundColor $color
        }
        
        $displayLines += "", "* = Action  |  [ ] = Submenu", "Up/Down=Navigate | Enter=Select | Shift+Enter=ShowDesc | 0/Backspace=Back | Q=Quit", ""
        Write-Host ""
        Write-Host "* = Action  |  [ ] = Submenu"
        Write-Host "Up/Down=Navigate | Enter=Select | Shift+Enter=ShowDesc | 0/Backspace=Back | Q=Quit"
        Write-Host ""
        Write-Transcript ($displayLines -join "`n")
        
        # Get key from either debug slow mode or actual console input
        if ($script:debugSlowMode) {
            $key = Get-DebugSlowModeKey
        } else {
            # Poll for shift state changes before blocking on key read
            while ($Host.UI.RawUI.KeyAvailable -eq $false) {
                Start-Sleep -Milliseconds 50
                # Check current shift state
                try {
                    $currentShiftState = [bool]([Console]::NumberLock)  # Dummy read to check state
                    # We can't directly poll shift without a key event, so we check on next key
                } catch {}
            }
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        $keyChar = $key.Character
        $virtualKey = $key.VirtualKeyCode
        
        # Check if shift is held (ControlKeyState 0x0010 = right shift, 0x0002 = left shift)
        $isShiftHeld = [bool]($key.ControlKeyState -band 0x0012)  # Both shift modifier bits
        
        # Update shift state for display refresh (triggers redraw on any key when shift changes)
        if ($isShiftCurrentlyHeld -ne $isShiftHeld) {
            $isShiftCurrentlyHeld = $isShiftHeld
            # Force redraw by continuing loop
            if ($virtualKey -eq 16) { continue }  # Pure shift press
        }
        $isShiftCurrentlyHeld = $isShiftHeld
        
        # Debug: Show shift detection
        if ($script:debugSlowMode -and $isShiftHeld) {
            Write-Host "[DEBUG] Shift key detected - will show description" -ForegroundColor Yellow
        }
        
        Log-Input "Key: $virtualKey ($keyChar), Shift: $isShiftHeld"
        Write-Transcript "INPUT: Key $virtualKey ($keyChar), Shift: $isShiftHeld"
        
        switch ($virtualKey) {
            38 { 
                $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $Items.Count - 1 }
                continue 
            }
            40 { 
                $selectedIndex = if ($selectedIndex -lt $Items.Count - 1) { $selectedIndex + 1 } else { 0 }
                continue 
            }
            16 {
                # Shift key pressed - redraw to show color change
                continue
            }
            13 { 
                if ($isShiftHeld) {
                    # Show description instead of selecting
                    Log-Input "Showing description for: $($Items[$selectedIndex]['Name'])"
                    Show-DescriptionBox -ItemName $Items[$selectedIndex]['Name'] -Description $Items[$selectedIndex]['Description']
                    $isShiftCurrentlyHeld = $false  # Reset after showing description
                    continue
                } else {
                    Log-Input "Selected: $selectedIndex"; 
                    return @{ Action = 'select'; Index = $selectedIndex }
                }
            }
            8  { return @{ Action = 'back'; Index = -1 } }
        }
        
        switch ($keyChar) {
            'q' { return @{ Action = 'quit'; Index = -1 } }
            'Q' { return @{ Action = 'quit'; Index = -1 } }
            '0' { return @{ Action = 'back'; Index = -1 } }
            default {
                if ($keyChar -match '^\d$') {
                    $index = [int]$keyChar - 1
                    if ($index -ge 0 -and $index -lt $Items.Count) {
                        Log-Input "Selected (numeric): $index"
                        return @{ Action = 'select'; Index = $index }
                    }
                }
            }
        }
    }
}

# ============================================================================
# OUTPUT HANDLER
# ============================================================================

function Invoke-OutputSelection {
    param(
        [string]$SelectedPath,
        [int]$ExitCode,
        [string]$OutputDir = $script:runSpacePath
    )
    
    # Write to file
    $selectionFile = Join-Path $OutputDir "selection.txt"
    Set-Content -Path $selectionFile -Value $SelectedPath -Encoding UTF8
    
    # Output to console
    Write-Host "Selected: $SelectedPath"
    
    # Exit with code
    exit $ExitCode
}

# ============================================================================
# MAIN INTERACTIVE LOOP
# ============================================================================

function Invoke-MainLoop {
    while ($true) {
        Log-Debug "Current path: $script:currentPath, Breadcrumb: $($script:breadcrumb -join ' > ')"
        
        # Get child buttons for current path
        $currentItems = @(Get-ChildButtons -ParentPath $script:currentPath)
        
        if ($currentItems.Count -eq 0) {
            Write-Host "No items in this menu" -ForegroundColor Red
            Log-Error "No items found for path: $script:currentPath"
            exit 1
        }
        
        # Show menu based on default_mode setting
        $mode = $script:settings.General['default_mode']
        if ($mode -eq 'interactive') {
            $result = Show-InteractiveMenu -Items $currentItems `
                -HighlightColor $script:settings.Colors['highlight_color'] `
                -ArrowColor $script:settings.Colors['arrow_color'] `
                -ShiftColor $script:settings.Colors['shift_color']
        } else {
            $result = Show-NumberedMenu -Items $currentItems `
                -HighlightColor $script:settings.Colors['highlight_color'] `
                -ShiftColor $script:settings.Colors['shift_color']
        }
        
        if ($result.Action -eq 'quit') {
            Log-Important "User quit"
            exit 99
        }
        
        if ($result.Action -eq 'back') {
            if ($script:breadcrumb.Count -gt 1) {
                $script:breadcrumb = $script:breadcrumb[0..($script:breadcrumb.Count - 2)]
                $script:currentPath = $script:breadcrumb[-1]
                Log-Navigation "Navigated back to: $script:currentPath"
            }
            continue
        }
        
        if ($result.Action -eq 'select') {
            if ($result.Index -lt 0 -or $null -eq $currentItems -or $result.Index -ge $currentItems.Count) {
                Log-Error "Invalid index: $($result.Index), items count: $($currentItems.Count)"
                Write-Host "Invalid index. Please try again." -ForegroundColor Red
                continue
            }
            
            $selectedItem = $currentItems[$result.Index]
            
            if ($selectedItem['Type'] -eq 'submenu') {
                # Navigate to submenu
                $script:currentPath = $selectedItem['Path']
                $script:breadcrumb += $selectedItem['Path']
                Log-Navigation "Opened submenu: $($selectedItem['Path'])"
            } else {
                # Option selected - output and exit
                $selectedIndex = $result.Index + 1
                Log-Important "Selected option: $($selectedItem['Name']) (path: $($selectedItem['Path']))"
                Invoke-OutputSelection -SelectedPath $selectedItem['Path'] -ExitCode $selectedIndex
            }
        }
    }
}

# ============================================================================
# CLI HANDLERS
# ============================================================================

function Invoke-AddButton {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Path,
        [string]$Type
    )
    
    if (Add-ButtonOption -Name $Name -Description $Description -Path $Path -Type $Type) {
        Write-Host "Button added successfully: $Path" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Failed to add button" -ForegroundColor Red
        return 1
    }
}

function Invoke-RemoveButton {
    param([string]$Path)
    
    if (Remove-ButtonOption -Path $Path) {
        Write-Host "Button removed successfully: $Path" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Failed to remove button" -ForegroundColor Red
        return 1
    }
}

function Invoke-ListButtons {
    $buttons = @($script:buttonIndex.Values) | Sort-Object Path
    
    if ($buttons.Count -eq 0) {
        Write-Host "No buttons found"
        return
    }
    
    Write-Host "Button List:" -ForegroundColor Green
    Write-Host "============"
    foreach ($button in $buttons) {
        $type = if ($button.Type -eq 'submenu') { '[S]' } else { '[O]' }
        Write-Host "$($type) $($button.Path): $($button.Name)"
    }
}

function Get-LanguageStub {
    param([string]$Language)
    
    $stubs = @{
        ps1 = @'
# PowerShell stub: Read selection from uiBuilder

$selectionFile = ".\run_space\selection.txt"
$selection = Get-Content -Path $selectionFile -ErrorAction Stop

Write-Host "You selected: $selection"

# Call your function here based on selection
switch ($selection) {
    "mainUI.settings.edit" { Edit-Settings }
    "mainUI.tools.python" { Invoke-PythonRunner }
    default { Write-Host "Unknown selection: $selection" }
}
'@
        bat = @'
REM Batch stub: Read selection from uiBuilder

@echo off
setlocal enabledelayedexpansion

set "selectionFile=run_space\selection.txt"

if not exist %selectionFile% (
    echo Selection file not found
    exit /b 1
)

for /f "usebackq delims=" %%a in ("%selectionFile%") do (
    set "selection=%%a"
)

echo You selected: !selection!

REM Call your function here based on selection
if "!selection!"=="mainUI.settings.edit" (
    call :EditSettings
) else if "!selection!"=="mainUI.tools.python" (
    call :InvokePythonRunner
)

exit /b 0

:EditSettings
    echo Running Edit Settings...
    exit /b 0

:InvokePythonRunner
    echo Running Python Runner...
    exit /b 0
'@
        py = @'
# Python stub: Read selection from uiBuilder

import sys
import os

selection_file = "run_space/selection.txt"

try:
    with open(selection_file, 'r') as f:
        selection = f.read().strip()
except FileNotFoundError:
    print("Selection file not found")
    sys.exit(1)

print(f"You selected: {selection}")

# Call your function here based on selection
if selection == "mainUI.settings.edit":
    print("Running Edit Settings...")
elif selection == "mainUI.tools.python":
    print("Running Python Runner...")
else:
    print(f"Unknown selection: {selection}")
'@
        cs = @'
// C# stub: Read selection from uiBuilder

using System;
using System.IO;

class Program {
    static int Main(string[] args) {
        string selectionFile = "run_space/selection.txt";
        
        if (!File.Exists(selectionFile)) {
            Console.WriteLine("Selection file not found");
            return 1;
        }
        
        string selection = File.ReadAllText(selectionFile).Trim();
        
        Console.WriteLine($"You selected: {selection}");
        
        // Call your function here based on selection
        switch (selection) {
            case "mainUI.settings.edit":
                EditSettings();
                break;
            case "mainUI.tools.python":
                InvokePythonRunner();
                break;
            default:
                Console.WriteLine($"Unknown selection: {selection}");
                break;
        }
        
        return 0;
    }
    
    static void EditSettings() {
        Console.WriteLine("Running Edit Settings...");
    }
    
    static void InvokePythonRunner() {
        Console.WriteLine("Running Python Runner...");
    }
}
'@
    }
    
    if ($stubs.ContainsKey($Language)) {
        return $stubs[$Language]
    } else {
        Write-Host "Language not supported: $Language" -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# ENTRY POINT
# ============================================================================

try {
    Initialize-Settings
    Initialize-ButtonIndex
    
    # Parse command line arguments
    if ($args.Count -eq 0) {
        # Interactive mode
        Invoke-MainLoop
    } else {
        # CLI mode
        $command = $args[0].ToLower()
        
        switch ($command) {
            "add" {
                if ($args.Count -lt 5) {
                    Write-Host "Usage: add <name> <description> <path> <type>"
                    exit 1
                }
                exit (Invoke-AddButton -Name $args[1] -Description $args[2] -Path $args[3] -Type $args[4])
            }
            
            "remove" {
                if ($args.Count -lt 2) {
                    Write-Host "Usage: remove <path>"
                    exit 1
                }
                exit (Invoke-RemoveButton -Path $args[1])
            }
            
            "list" {
                Invoke-ListButtons
                exit 0
            }
            
            "--generate-stub" {
                if ($args.Count -lt 2) {
                    Write-Host "Usage: --generate-stub <language>"
                    exit 1
                }
                $stub = Get-LanguageStub -Language $args[1]
                if ($stub) {
                    Write-Host $stub
                    exit 0
                } else {
                    exit 1
                }
            }
            
            "--debug" {
                $script:debugMode = $true
                Log-Important "Debug mode enabled"
                Invoke-MainLoop
            }
            
            default {
                Write-Host "Unknown command: $command"
                exit 1
            }
        }
    }
}
catch {
    Log-Error "$($_.Exception.Message) at $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    exit 1
}
