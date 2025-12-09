#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
  VERSION_UPDATER.ps1
  
  Automated version update script for termUI.
  Used by GitHub Actions or manual update scripts to:
  1. Check if local version matches expected version
  2. Increment version in VERSION.json
  3. Add changelog entries
  
  Usage:
    .\VERSION_UPDATER.ps1 -TermUIRoot "C:\cmd\termUI" -NewVersion "1.1.0" -Changes @("Feature 1", "Bug fix")
    
  Or for GitHub compatibility:
    .\VERSION_UPDATER.ps1 -RemoteVersion "1.1.0" -Check
#>

# Parse parameters from command line
$TermUIRoot = $null
$NewVersion = $null
$Changes = @()
$Check = $false
$CurrentVersion = $null
$Force = $false

# Handle both -File execution and direct parameter passing
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "-TermUIRoot" { $TermUIRoot = $args[$i + 1]; $i += 2 }
        "-NewVersion" { $NewVersion = $args[$i + 1]; $i += 2 }
        "-Changes" { $Changes = @($args[$i + 1] -split ','); $i += 2 }
        "-Check" { $Check = $true; $i += 1 }
        "-CurrentVersion" { $CurrentVersion = $args[$i + 1]; $i += 2 }
        "-Force" { $Force = $true; $i += 1 }
        "-Verbose" { $VerbosePreference = "Continue"; $i += 1 }
        default { $i += 1 }
    }
}



# Resolve TermUIRoot if not provided
if (-not $TermUIRoot) {
    # Script is at termUI/VERSION_UPDATER.ps1, so parent is termUI directory
    $TermUIRoot = Split-Path -Parent $PSCommandPath
    if (-not $TermUIRoot) {
        $TermUIRoot = Get-Location
    }
}

if (-not (Test-Path $TermUIRoot)) {
    Write-Error "TermUIRoot not found: $TermUIRoot"
    exit 1
}

# Load VersionManager
$versionManagerPath = Join-Path $TermUIRoot "powershell" "modules" "VersionManager.ps1"
if (-not (Test-Path $versionManagerPath)) {
    Write-Error "VersionManager.ps1 not found at $versionManagerPath"
    exit 1
}

. $versionManagerPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  termUI Version Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current version
try {
    $currentData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $installedVersion = $currentData.version
    Write-Host "Installed Version: $installedVersion" -ForegroundColor Green
} catch {
    Write-Error "Failed to read current version: $_"
    exit 1
}

# Check mode only
if ($Check) {
    Write-Host "Check Mode: Comparing versions..." -ForegroundColor Yellow
    Write-Host "  Installed: $installedVersion"
    Write-Host "  GitHub: $NewVersion"
    
    $comparison = Compare-TermUIVersion -LocalVersion $installedVersion -RemoteVersion $NewVersion
    if ($comparison -eq -1) {
        Write-Host "  Status: UPDATE AVAILABLE" -ForegroundColor Green
        exit 0
    } elseif ($comparison -eq 0) {
        Write-Host "  Status: UP TO DATE" -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "  Status: LOCAL VERSION AHEAD" -ForegroundColor Magenta
        exit 0
    }
}

# Update mode
if (-not $NewVersion) {
    Write-Error "NewVersion parameter required for update mode"
    exit 1
}

Write-Host "Update Mode:" -ForegroundColor Yellow
Write-Host "  Target Version: $NewVersion"

# Validate version format
try {
    $versionTest = [version]$NewVersion
    if ($versionTest -le [version]$installedVersion) {
        Write-Error "New version ($NewVersion) must be greater than installed version ($installedVersion)"
        exit 1
    }
} catch {
    Write-Error "Invalid version format: $NewVersion (expected semantic version like 1.1.0)"
    exit 1
}

# Validate current version match if provided
if ($CurrentVersion -and -not $Force) {
    if (-not (Test-TermUIVersionMatch -TermUIRoot $TermUIRoot -ExpectedVersion $CurrentVersion)) {
        Write-Error "Version mismatch: Expected $CurrentVersion, but installed version is $installedVersion"
        Write-Host "  Use -Force to skip validation" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Version validation: PASSED" -ForegroundColor Green
}

# Create default changelog if not provided
if (-not $Changes -or $Changes.Count -eq 0) {
    $Changes = @("Updated to version $NewVersion")
}

Write-Host "  Changelog entries:"
$Changes | ForEach-Object { Write-Host "    * $_" }

# Perform update
Write-Host ""
Write-Host "Applying update..." -ForegroundColor Cyan

try {
    Update-TermUIVersion -TermUIRoot $TermUIRoot -NewVersion $NewVersion -Changes $Changes
    Write-Host "✓ Version updated successfully" -ForegroundColor Green
    
    # Create version marker file for audit
    $markerPath = New-TermUIVersionCheckFile -TermUIRoot $TermUIRoot
    Write-Host "✓ Version marker created: $markerPath" -ForegroundColor Green
    
    # Verify update
    $updatedData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    if ($updatedData.version -eq $NewVersion) {
        Write-Host ""
        Write-Host "Update Complete!" -ForegroundColor Green
        Write-Host "  New Version: $($updatedData.version)" -ForegroundColor Green
        Write-Host "  Updated: $($updatedData.lastUpdated)" -ForegroundColor Green
        exit 0
    } else {
        Write-Error "Version verification failed after update"
        exit 1
    }
} catch {
    Write-Error "Update failed: $_"
    exit 1
}
