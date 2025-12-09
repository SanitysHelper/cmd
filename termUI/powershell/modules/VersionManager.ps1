#Requires -Version 5.0
Set-StrictMode -Version Latest

<#
  VersionManager.ps1
  Manages termUI versioning, version comparison, and update detection.
  Enables automatic update checking against GitHub releases.
#>

function Get-TermUIVersion {
    <#
    .SYNOPSIS
        Read the current installed version from VERSION.json
    .PARAMETER TermUIRoot
        Path to termUI root directory (defaults to script directory)
    .EXAMPLE
        $version = Get-TermUIVersion -TermUIRoot "C:\cmd\termUI"
        Write-Host "Current version: $($version.version)"
    #>
    param(
        [Parameter()][string]$TermUIRoot = (Split-Path -Parent $PSScriptRoot)
    )
    
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
    <#
    .SYNOPSIS
        Compare two semantic versions (e.g., "1.2.3" vs "1.2.4")
    .PARAMETER LocalVersion
        Installed version string (e.g., "1.0.0")
    .PARAMETER RemoteVersion
        GitHub/remote version string (e.g., "1.1.0")
    .RETURNS
        -1 if LocalVersion < RemoteVersion (update available)
         0 if versions are equal (up-to-date)
         1 if LocalVersion > RemoteVersion (ahead of remote)
    .EXAMPLE
        $result = Compare-TermUIVersion -LocalVersion "1.0.0" -RemoteVersion "1.1.0"
        if ($result -eq -1) { Write-Host "Update available!" }
    #>
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
    <#
    .SYNOPSIS
        Check if an update is available by comparing local vs remote version
    .PARAMETER LocalVersion
        Installed version string
    .PARAMETER RemoteVersion
        GitHub/remote version string
    .RETURNS
        $true if update is available, $false otherwise
    .EXAMPLE
        $isUpdateAvailable = Test-TermUIUpdateAvailable -LocalVersion "1.0.0" -RemoteVersion "1.1.0"
    #>
    param(
        [Parameter(Mandatory)][string]$LocalVersion,
        [Parameter(Mandatory)][string]$RemoteVersion
    )
    
    $comparison = Compare-TermUIVersion -LocalVersion $LocalVersion -RemoteVersion $RemoteVersion
    return $comparison -eq -1
}

function Update-TermUIVersion {
    <#
    .SYNOPSIS
        Update the local VERSION.json with new version and changelog entry
    .PARAMETER TermUIRoot
        Path to termUI root directory
    .PARAMETER NewVersion
        New semantic version (e.g., "1.1.0")
    .PARAMETER Changes
        Array of change descriptions
    .EXAMPLE
        Update-TermUIVersion -TermUIRoot "C:\cmd\termUI" -NewVersion "1.1.0" `
            -Changes @("Added new feature", "Fixed bug in menu rendering")
    #>
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
    <#
    .SYNOPSIS
        Get a formatted version string for display
    .PARAMETER TermUIRoot
        Path to termUI root directory
    .RETURNS
        Formatted string like "termUI v1.0.0 (2025-12-08)"
    .EXAMPLE
        $versionString = Get-TermUIVersionString
        Write-Host $versionString
    #>
    param(
        [Parameter()][string]$TermUIRoot = (Split-Path -Parent $PSScriptRoot)
    )
    
    $versionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $date = ([datetime]$versionData.lastUpdated).ToString("yyyy-MM-dd")
    return "termUI v$($versionData.version) ($date)"
}

function Get-TermUIChangelog {
    <#
    .SYNOPSIS
        Get formatted changelog
    .PARAMETER TermUIRoot
        Path to termUI root directory
    .PARAMETER EntryCount
        Number of changelog entries to return (default: 5)
    .EXAMPLE
        Get-TermUIChangelog -TermUIRoot "C:\cmd\termUI" -EntryCount 3
    #>
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
    <#
    .SYNOPSIS
        Create a version check marker file for future GitHub comparison
    .PARAMETER TermUIRoot
        Path to termUI root directory
    .RETURNS
        Path to created version marker file in _debug/
    .EXAMPLE
        $markerPath = New-TermUIVersionCheckFile -TermUIRoot "C:\cmd\termUI"
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot
    )
    
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
    <#
    .SYNOPSIS
        Check if installed version matches expected version
        (Used by auto-update script to ensure correct version before updating)
    .PARAMETER TermUIRoot
        Path to termUI root directory
    .PARAMETER ExpectedVersion
        Expected version to match
    .RETURNS
        $true if versions match, $false otherwise
    .EXAMPLE
        if (Test-TermUIVersionMatch -TermUIRoot "C:\cmd\termUI" -ExpectedVersion "1.0.0") {
            Write-Host "Ready for update to next version"
        }
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$ExpectedVersion
    )
    
    $currentVersion = (Get-TermUIVersion -TermUIRoot $TermUIRoot).version
    return $currentVersion -eq $ExpectedVersion
}

# Export functions
Export-ModuleMember -Function @(
    'Get-TermUIVersion',
    'Compare-TermUIVersion',
    'Test-TermUIUpdateAvailable',
    'Update-TermUIVersion',
    'Get-TermUIVersionString',
    'Get-TermUIChangelog',
    'New-TermUIVersionCheckFile',
    'Test-TermUIVersionMatch'
)
