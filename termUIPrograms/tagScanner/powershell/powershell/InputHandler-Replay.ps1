#Requires -Version 5.0
<#
.SYNOPSIS
    Simple input replay handler for termUI test mode
.DESCRIPTION
    Reads a JSON file containing input events and outputs them line-by-line for termUI to consume
.PARAMETER Replay
    Path to the JSON file containing the input sequence
#>

param(
    [Parameter(Mandatory)]
    [string]$Replay
)

if (-not (Test-Path $Replay)) {
    Write-Error "Test file not found: $Replay"
    exit 1
}

try {
    $events = Get-Content -Path $Replay -Raw | ConvertFrom-Json
    
    foreach ($event in $events) {
        # Output each event as a single-line JSON for termUI to parse
        $event | ConvertTo-Json -Compress
    }
    
    exit 0
} catch {
    Write-Error "Failed to replay events: $_"
    exit 1
}
