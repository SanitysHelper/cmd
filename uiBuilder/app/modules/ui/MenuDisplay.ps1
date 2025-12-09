# ============================================================================
# UI DISPLAY MODULE
# ============================================================================
# Handles interactive and numbered menu display, debug slow mode, and formatting

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
        $script:debugDelays = @(700,700,650,600,500,400,300,250,200,150,120)  # progressive speed-up
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

        # Adaptive pacing: slower first, then speed up. Clamp to last delay if sequence is longer.
        $delayIdx = [Math]::Min($script:debugSequenceIndex - 1, $script:debugDelays.Count - 1)
        Start-Sleep -Milliseconds $script:debugDelays[$delayIdx]
        return $key
    } else {
        # Sequence completed, auto-quit to prevent hanging
        Write-Host "[DEBUG] Sequence complete - auto-quitting to prevent input wait" -ForegroundColor Magenta
        # Return Q key to quit gracefully
        return @{ VirtualKeyCode = 81; Character = 'q'; ControlKeyState = 0 }  # 81 = Q
    }
}

function Show-NumberedMenu {
    param(
        [array]$Items,
        [string]$HighlightColor = 'Green',
        [string]$ShiftColor = 'Yellow'
    )
    
    $itemCount = @($Items).Count  # Ensure array even for single item
    if ($itemCount -eq 0) {
        Write-Host "No items available" -ForegroundColor Red
        return @{ Action = 'back'; Index = -1 }
    }
    
    Log-Debug "Menu with $itemCount items"
    
    while ($true) {
        if (-not [Console]::IsInputRedirected) { Clear-Host }
        
        # Numbered mode: White text only for fast debugging
        $displayLines = @("================================", "SELECT OPTION:", "================================")
        Write-Host "================================" -ForegroundColor White
        Write-Host "SELECT OPTION:" -ForegroundColor White
        Write-Host "================================" -ForegroundColor White
        
        for ($i = 0; $i -lt $itemCount; $i++) {
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
        
        # Log menu frame state (even in numbered mode)
        Log-MenuFrame -Items $Items -SelectedIndex -1 -IsShiftHeld $false -IsEnterHeld $false
        
        try {
            # In debug slow mode, never prompt for input - it should use Get-DebugSlowModeKey instead
            if ($script:debugSlowMode) {
                Log-Input -Message "Debug mode: numbered menu should not be reached" -Source "NumberedMenu"
                return @{ Action = 'quit'; Index = -1 }
            }
            Log-InputTiming -Action "PROMPT_WAIT_START" -Details "Numbered menu awaiting input"
            $userInput = if ([Console]::IsInputRedirected) {
                [Console]::In.ReadLine()
            } else {
                Read-Host "Enter number"
            }
            Log-InputTiming -Action "PROMPT_WAIT_END" -Details "Input received"
        }
        catch {
            Log-Input -Message "EOF" -Source "NumberedMenu"
            return @{ Action = 'quit'; Index = -1 }
        }
        
        if ($null -eq $userInput) {
            Log-Input -Message "Empty" -Source "NumberedMenu"
            return @{ Action = 'quit'; Index = -1 }
        }
        
        $userInput = $userInput.Trim().ToLower()
        Log-Input -Message $userInput -Source "NumberedMenu"
        Write-Transcript "INPUT: $userInput"
        
        switch ($userInput) {
            'q' { return @{ Action = 'quit'; Index = -1 } }
            '0' { return @{ Action = 'back'; Index = -1 } }
            default {
                if ($userInput -match '^\d+$') {
                    $index = [int]$userInput - 1
                    if ($index -ge 0 -and $index -lt $itemCount) {
                        Log-Input -Message "Selected: $index" -Source "NumberedMenu"
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
    
    # In debug slow mode, enqueue an Enter press/release so we don't hang
    if ($script:debugSlowMode -and $script:InjectedKeyQueue.Count -eq 0) {
        Add-InjectedKey -VirtualKeyCode 13 -Char 0 -IsDown $true  -ControlKeyState 0
        Add-InjectedKey -VirtualKeyCode 13 -Char 0 -IsDown $false -ControlKeyState 0
    }

    # Wait for keypress using the C# handler (ignores pure modifier keys)
    while ($true) {
        $key = Get-KeyboardInput
        if (-not $key) { continue }
        $vk = $key.VirtualKeyCode
        if ($vk -eq 16 -or $vk -eq 17 -or $vk -eq 18) { continue }
        break
    }
}

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
    
    $itemCount = @($Items).Count  # Ensure array even for single item
    if ($itemCount -eq 0) {
        Write-Host "No items available" -ForegroundColor Red
        return @{ Action = 'back'; Index = -1 }
    }
    
    # Fall back to numbered menu if piped (unless in debug_slow_mode)
    if ([Console]::IsInputRedirected -and -not $script:debugSlowMode) {
        return Show-NumberedMenu -Items $Items -HighlightColor $HighlightColor
    }
    
    $selectedIndex = 0
    $isShiftCurrentlyHeld = $false
    $isEnterCurrentlyHeld = $false
    
    while ($true) {
        Clear-Host
        $displayLines = @("================================", "SELECT OPTION (use arrow keys):", "================================")
        Write-Host "================================" -ForegroundColor $ArrowColor
        Write-Host "SELECT OPTION (use arrow keys):" -ForegroundColor $ArrowColor
        Write-Host "================================" -ForegroundColor $ArrowColor
        Write-Host ""
        
        # Log menu frame on every display
        Log-MenuFrame -Items $Items -SelectedIndex $selectedIndex -IsShiftHeld $isShiftCurrentlyHeld -IsEnterHeld $isEnterCurrentlyHeld
        
        for ($i = 0; $i -lt $itemCount; $i++) {
            $prefix = if ($i -eq $selectedIndex) { ">> " } else { "   " }
            # Change color based on: enter held (red), shift held (yellow), or normal highlight
            $color = if ($i -eq $selectedIndex) { 
                if ($isEnterCurrentlyHeld) { 'Red' }
                elseif ($isShiftCurrentlyHeld) { $ShiftColor } 
                else { $HighlightColor }
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
        
        # Show status line indicating held keys
        $statusIndicators = @()
        if ($isEnterCurrentlyHeld) { $statusIndicators += "[ENTER HELD - RED]" }
        if ($isShiftCurrentlyHeld) { $statusIndicators += "[SHIFT HELD]" }
        $statusLine = if ($statusIndicators.Count -gt 0) { " | " + ($statusIndicators -join " ") } else { "" }
        
        Write-Host ""
        Write-Host "* = Action  |  [ ] = Submenu"
        Write-Host "Up/Down=Navigate | Enter=Select | Shift+Enter=ShowDesc | 0/Backspace=Back | Q=Quit$statusLine" -ForegroundColor Cyan
        Write-Host ""
        Write-Transcript ($displayLines -join "`n")
        
        # Get key from either debug slow mode or actual console input
        if ($script:debugSlowMode) {
            $key = Get-DebugSlowModeKey
            Log-InputTiming -Action "DEBUG_KEY_SIMULATED" -Details "VK=$($key.VirtualKeyCode)"
        } else {
            # Use C# keyboard handler for better input detection
            Log-InputTiming -Action "INTERACTIVE_WAIT_START" -Details "Waiting for keyboard input"
            $key = Get-KeyboardInput
            Log-InputTiming -Action "INTERACTIVE_WAIT_END" -Details "Key received: VK=$($key.VirtualKeyCode), IsDown=$($key.IsKeyDown), Shift=$($key.IsShift)"
        }
        if (-not $key -or -not $key.PSObject.Properties['VirtualKeyCode']) {
            Log-Error "Keyboard input unavailable (null key)."; Start-Sleep -Milliseconds 50; continue
        }
        $keyChar = $key.Character
        $virtualKey = $key.VirtualKeyCode

        # Robust shift/key-state detection (supports debug slow-mode objects)
        $isShiftHeld = if ($key.PSObject.Properties['IsShift']) { $key.IsShift } else { [bool]($key.ControlKeyState -band 0x0012) }
        $isKeyDown = if ($key.PSObject.Properties['IsKeyDown']) { $key.IsKeyDown } else { $true }
        
        # Check if Enter is currently held (key code 13)
        if ($virtualKey -eq 13 -and $isKeyDown) {
            $isEnterCurrentlyHeld = $true
        } elseif ($virtualKey -eq 13 -and -not $isKeyDown) {
            $isEnterCurrentlyHeld = $false
        }
        
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
        
        Log-Input -Message "Key: $virtualKey ($keyChar), Shift: $isShiftHeld" -Source "InteractiveMenu"
        Write-Transcript "INPUT: Key $virtualKey ($keyChar), Shift: $isShiftHeld"
        
        switch ($virtualKey) {
            38 { 
                $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $itemCount - 1 }
                continue 
            }
            40 { 
                $selectedIndex = if ($selectedIndex -lt $itemCount - 1) { $selectedIndex + 1 } else { 0 }
                continue 
            }
            16 {
                # Shift key pressed - redraw to show color change
                continue
            }
            13 { 
                if ($isShiftHeld) {
                    # Show description instead of selecting
                    Log-Input -Message "Showing description for: $($Items[$selectedIndex]['Name'])" -Source "InteractiveMenu"
                    Log-InputTiming -Action "DESCRIPTION_WAIT_START" -Details "Displaying description box"
                    
                    Clear-Host
                    Write-Host "`n" -ForegroundColor Yellow
                    Write-Host "=== DISPLAYING DESCRIPTION BOX ===" -ForegroundColor Yellow
                    Write-Host "`n" -ForegroundColor Yellow
                    Show-DescriptionBox -ItemName $Items[$selectedIndex]['Name'] -Description $Items[$selectedIndex]['Description']
                    Write-Host "`n" -ForegroundColor Yellow
                    Write-Host "=== DESCRIPTION BOX CLOSED ===" -ForegroundColor Yellow
                    Write-Host "`n" -ForegroundColor Yellow
                    Write-Host "Press ENTER to continue..." -ForegroundColor Yellow
                    
                    # Wait for user to press Enter to continue using the C# handler (more reliable)
                    Log-InputTiming -Action "DESCRIPTION_WAIT_FOR_ENTER_START" -Details "Waiting for Enter release"
                    while ($true) {
                        $continueKey = Get-KeyboardInput
                        if ($continueKey -and $continueKey.VirtualKeyCode -eq 13 -and -not $continueKey.IsKeyDown) {
                            # Enter released - continue program
                            break
                        }
                    }
                    Log-InputTiming -Action "DESCRIPTION_WAIT_FOR_ENTER_END" -Details "Enter released"
                    
                    Log-InputTiming -Action "DESCRIPTION_WAIT_END" -Details "User pressed Enter to close description"
                    $isShiftCurrentlyHeld = $false  # Reset after showing description
                    $isEnterCurrentlyHeld = $false  # Reset enter hold
                    continue
                } else {
                    Log-Input -Message "Selected: $selectedIndex" -Source "InteractiveMenu"; 
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
                    if ($index -ge 0 -and $index -lt $itemCount) {
                        Log-Input -Message "Selected (numeric): $index" -Source "InteractiveMenu"
                        return @{ Action = 'select'; Index = $index }
                    }
                }
            }
        }
    }
}
