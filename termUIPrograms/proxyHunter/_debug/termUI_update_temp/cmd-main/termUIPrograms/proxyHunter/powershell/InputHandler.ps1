#Requires -Version 5.0
<#
.SYNOPSIS
Input Handler for termUI - Converts console input to JSON events
Supports both interactive mode and replay mode for testing

.PARAMETER Replay
Path to test file containing JSON-formatted input events (one per line)
#>

[CmdletBinding()]
param(
    [Parameter()][string]$Replay = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($Replay) {
    # TEST MODE: Replay events from file
    if (-not (Test-Path $Replay)) {
        Write-Error "Test file not found: $Replay" | Out-String | Write-Host
        exit 1
    }
    
    try {
        $lines = Get-Content -Path $Replay -Raw -ErrorAction Stop
        $events = $lines -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
        foreach ($event in $events) {
            Write-Output $event
        }
    } catch {
        Write-Error "Failed to read replay file: $_" | Out-String | Write-Host
        exit 1
    }
} else {
    # INTERACTIVE MODE: Read from console and output JSON events
    Write-Host "Input Handler running in interactive mode..." -ForegroundColor DarkGray -ErrorAction SilentlyContinue | Out-Null
    
    while ($true) {
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
                    elseif ($ch -eq 'p' -or $ch -eq 'P') { "P" }
                    elseif ([char]::IsLetterOrDigit($ch) -or [char]::IsPunctuation($ch)) { "Char" }
                    else { "" }
                }
            }
            
            if ($keyName) {
                $evt = @{ key = $keyName; char = $key.KeyChar } | ConvertTo-Json -Compress
                Write-Output $evt
                
                # If Q pressed, exit
                if ($keyName -eq "Q") {
                    break
                }
            }
        } else {
            [System.Threading.Thread]::Sleep(50)
        }
    }
}

