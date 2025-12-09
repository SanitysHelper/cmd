function Stop-InputHandler {
    param($Handler)
    if ($null -eq $Handler) { return }
    try { 
        if ($Handler.Writer) { $Handler.Writer.Close() }
        if (-not $Handler.Process.HasExited) { $Handler.Process.Kill() } 
    } catch {}
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
    
    # Interactive mode: read directly from console
    if ($Handler.PSObject.Properties['IsInteractive'] -and $Handler.IsInteractive) {
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
