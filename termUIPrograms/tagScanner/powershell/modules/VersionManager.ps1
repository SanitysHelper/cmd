#Requires -Version 5.0
Set-StrictMode -Version Latest

function Get-TermUIVersion {
    param([Parameter()][string]$TermUIRoot = (Split-Path -Parent $PSScriptRoot))
    
    $versionFile = Join-Path $TermUIRoot "VERSION.json"
    if (-not (Test-Path $versionFile)) {
        throw "VERSION.json not found at $versionFile"
    }
    
    try {
        $versionData = Get-Content -Path $versionFile -Raw | ConvertFrom-Json
        return $versionData
    } catch {
        throw "Failed to parse VERSION.json: $_"
    }
}

function Compare-TermUIVersion {
    param(
        [Parameter(Mandatory)][string]$LocalVersion,
        [Parameter(Mandatory)][string]$RemoteVersion
    )
    
    # Parse versions into [version] objects for comparison
    try {
        $local = [version]$LocalVersion
        $remote = [version]$RemoteVersion
    } catch {
        throw "Invalid version format. Expected semantic version (e.g., 1.0.0): Local=$LocalVersion, Remote=$RemoteVersion"
    }
    
    if ($local -lt $remote) { return -1 }
    if ($local -gt $remote) { return 1 }
    return 0
}

function Test-TermUIUpdateAvailable {
    param(
        [Parameter(Mandatory)][string]$LocalVersion,
        [Parameter(Mandatory)][string]$RemoteVersion
    )
    
    $comparison = Compare-TermUIVersion -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion
    return $comparison -eq -1
}

function Update-TermUIVersion {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$NewVersion,
        [Parameter(Mandatory)][string[]]$Changes
    )
    
    $versionFile = Join-Path $TermUIRoot "VERSION.json"
    $versionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    
    # Create changelog entry
    $changelogEntry = @{
        version = $NewVersion
        date = (Get-Date -Format "yyyy-MM-dd")
        changes = $Changes
    }
    
    # Update version data
    $versionData.version = $NewVersion
    $versionData.lastUpdated = (Get-Date -Format "o")
    $versionData.changelog = @($changelogEntry) + @($versionData.changelog)
    
    # Write back to file (preserve formatting)
    $versionData | ConvertTo-Json -Depth 10 | Set-Content -Path $versionFile -Encoding UTF8
    Write-Verbose "[VersionManager] Updated version to $NewVersion"
}

function Get-TermUIVersionString {
    param([Parameter()][string]$TermUIRoot = (Split-Path -Parent $PSScriptRoot))
    
    $versionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $date = ([datetime]$versionData.lastUpdated).ToString("yyyy-MM-dd")
    return "termUI v$($versionData.version) ($date)"
}

function Get-TermUIChangelog {
    param(
        [Parameter()][string]$TermUIRoot = (Split-Path -Parent $PSScriptRoot),
        [Parameter()][int]$EntryCount = 5
    )
    
    $versionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $entries = $versionData.changelog | Select-Object -First $EntryCount
    
    $output = @()
    foreach ($entry in $entries) {
        $output += "v$($entry.version) - $($entry.date)"
        foreach ($change in $entry.changes) {
            $output += "  * $change"
        }
        $output += ""
    }
    
    return $output -join "`n"
}

function New-TermUIVersionCheckFile {
    param([Parameter(Mandatory)][string]$TermUIRoot)
    
    $debugDir = Join-Path $TermUIRoot "_debug"
    if (-not (Test-Path $debugDir)) {
        New-Item -ItemType Directory -Path $debugDir -Force | Out-Null
    }
    
    $versionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $markerFile = Join-Path $debugDir "CURRENT_VERSION.txt"
    
    $markerContent = @"
termUI Version Check
====================
Current Version: $($versionData.version)
Last Updated: $($versionData.lastUpdated)
Installed On: $(Get-Date -Format 'o')

This file is used by auto-update scripts to detect version changes.
DO NOT EDIT MANUALLY.
"@
    
    $markerContent | Set-Content -Path $markerFile -Encoding UTF8
    return $markerFile
}

function Test-TermUIVersionMatch {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$ExpectedVersion
    )
    
    $currentVersion = (Get-TermUIVersion -TermUIRoot $TermUIRoot).version
    return $currentVersion -eq $ExpectedVersion
}
