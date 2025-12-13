function Stop-InputHandler {
    param($Handler)
    if ($null -eq $Handler) { return }
    try { 
        if ($Handler.Writer) { $Handler.Writer.Close() }
        if ($Handler.Process -and -not $Handler.Process.HasExited) { $Handler.Process.Kill() } 
    } catch {}
}

function Get-TestInput {
    param(
        [object]$EventBuffer,
        [object]$Handler
    )

    # In test mode, collect characters until Enter is pressed
    if ($Handler.PSObject.Properties['IsTestMode'] -and $Handler.IsTestMode) {
        $inputBuffer = ""
        while ($EventBuffer.Count -gt 0) {
            $evt = $EventBuffer.Peek()
            if ($evt.key -eq "Enter") {
                # Consume the Enter event
                $EventBuffer.Dequeue() | Out-Null
                return $inputBuffer
            } elseif ($evt.key -eq "Backspace") {
                $EventBuffer.Dequeue() | Out-Null
                if ($inputBuffer.Length -gt 0) {
                    $inputBuffer = $inputBuffer.Substring(0, $inputBuffer.Length - 1)
                }
            } elseif ($evt.key -eq "Char") {
                $EventBuffer.Dequeue() | Out-Null
                $inputBuffer += $evt.char
            } else {
                # Stop collecting if we hit a non-text input key
                break
            }
        }
        return $inputBuffer
    }
    return $null
}

function Get-NextInputEvent {
    param($Handler)
    
    # Test mode with buffered events
    if ($Handler.PSObject.Properties['IsTestMode'] -and $Handler.IsTestMode) {
        if ($Handler.EventBuffer.Count -gt 0) {
            return $Handler.EventBuffer.Dequeue()
        }
        return $null
    }
    
    # Piped input mode (stdin is redirected)
    if ($Handler.PSObject.Properties['IsPipedInput'] -and $Handler.IsPipedInput) {
        try {
            if ($Host.UI.RawUI.KeyAvailable) {
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                $keyName = switch ($key.VirtualKeyCode) {
                    38 { "Up" }      # Up arrow
                    40 { "Down" }    # Down arrow
                    37 { "Left" }    # Left arrow
                    39 { "Right" }   # Right arrow
                    13 { "Enter" }   # Enter
                    27 { "Escape" }  # Escape
                    9  { "Tab" }     # Tab
                    8  { "Backspace" } # Backspace
                    81 { "Q" }       # Q key
                    default {
                        $ch = $key.Character
                        if ([string]::IsNullOrEmpty($ch)) { "" }
                        elseif ($ch -eq 'q' -or $ch -eq 'Q') { "Q" }
                        elseif ([char]::IsDigit($ch)) { $ch }
                        else { "" }
                    }
                }
                if ($keyName) {
                    return [pscustomobject]@{ key = $keyName; char = $key.Character }
                }
            }
        } catch {
            # Silently continue if no input available
        }
        return $null
    }
    
    # Interactive mode: read directly from console
    if ($Handler.PSObject.Properties['IsInteractive'] -and $Handler.IsInteractive) {
        # Check if console input is available (try-catch for error conditions)
        try {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $keyName = switch ($key.Key) {
                    "UpArrow" { "Up" }
                    "DownArrow" { "Down" }
                    "LeftArrow" { "Left" }
                    "RightArrow" { "Right" }
                    "Enter" { "Enter" }
                    "Escape" { "Escape" }
                    "Tab" { "Tab" }
                    "Backspace" { "Backspace" }
                    default {
                        $ch = $key.KeyChar
                        if ($ch -eq 'q' -or $ch -eq 'Q') { "Q" }
                        elseif ([char]::IsLetterOrDigit($ch) -or [char]::IsPunctuation($ch)) { "Char" }
                        else { "" }
                    }
                }
                if ($keyName) {
                    return [pscustomobject]@{ key = $keyName; char = $key.KeyChar }
                }
            }
        } catch {
            # Console.KeyAvailable threw an error (likely input is redirected)
            # Fall back to Host.UI.RawUI for piped input
            try {
                if ($Host.UI.RawUI.KeyAvailable) {
                    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    $keyName = switch ($key.VirtualKeyCode) {
                        38 { "Up" }
                        40 { "Down" }
                        37 { "Left" }
                        39 { "Right" }
                        13 { "Enter" }
                        27 { "Escape" }
                        9  { "Tab" }
                        8  { "Backspace" }
                        81 { "Q" }
                        default {
                            $ch = $key.Character
                            if ([char]::IsDigit($ch)) { $ch }
                            elseif ($ch -eq 'q' -or $ch -eq 'Q') { "Q" }
                            else { "" }
                        }
                    }
                    if ($keyName) {
                        return [pscustomobject]@{ key = $keyName; char = $key.Character }
                    }
                }
            } catch {
                # Still failed, no more input available
            }
        }
        return $null
    }
    
    # Subprocess mode: read from handler's stdout
    if ($null -eq $Handler -or $null -eq $Handler.Reader) {
        return $null
    }
    
    try {
        $line = $Handler.Reader.ReadLine()
        if ($null -eq $line) { return $null }
        return $line | ConvertFrom-Json
    } catch {
        Log-Error "Failed to parse input event: $_"
        return $null
    }
}
