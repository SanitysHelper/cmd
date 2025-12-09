#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
  GitHub-VersionCheck.ps1
  
  Integrates termUI with GitHub releases for automatic version detection.
  Fetches the latest release version from GitHub API and compares with local version.
  
  Usage:
    .\GitHub-VersionCheck.ps1 -TermUIRoot "C:\cmd\termUI"
    .\GitHub-VersionCheck.ps1 -CheckOnly
    .\GitHub-VersionCheck.ps1 -AutoUpdate
#>

# Parse parameters from command line
$TermUIRoot = $null
$GitHubRepo = "SanitysHelper/cmd"
$GitHubToken = $null
$CheckOnly = $false
$AutoUpdate = $false
$Verbose = $false

# Handle both -File execution and direct parameter passing
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "-TermUIRoot" { $TermUIRoot = $args[$i + 1]; $i += 2 }
        "-GitHubRepo" { $GitHubRepo = $args[$i + 1]; $i += 2 }
        "-GitHubToken" { $GitHubToken = $args[$i + 1]; $i += 2 }
        "-CheckOnly" { $CheckOnly = $true; $i += 1 }
        "-AutoUpdate" { $AutoUpdate = $true; $i += 1 }
        "-Verbose" { $VerbosePreference = "Continue"; $i += 1 }
        default { $i += 1 }
    }
}

# Resolve TermUIRoot if not provided
if (-not $TermUIRoot) {
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
Write-Host "  termUI GitHub Version Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current local version
try {
    $localVersionData = Get-TermUIVersion -TermUIRoot $TermUIRoot
    $localVersion = $localVersionData.version
    Write-Host "Local Version: $localVersion" -ForegroundColor Green
} catch {
    Write-Error "Failed to read local version: $_"
    exit 1
}

Write-Host "GitHub Repository: $GitHubRepo" -ForegroundColor Yellow
Write-Host ""
Write-Host "Fetching latest release from GitHub..." -ForegroundColor Cyan

# Fetch latest release from GitHub API
$apiUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "termUI-VersionChecker"
}

# Add auth token if provided (for higher rate limits)
if ($GitHubToken) {
    $headers["Authorization"] = "token $GitHubToken"
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 10
    
    if (-not $response -or -not $response.tag_name) {
        Write-Host "No releases found on GitHub" -ForegroundColor Yellow
        exit 0
    }
    
    # Parse version from tag (handles "v1.0.0" or "1.0.0" formats)
    $remoteVersion = $response.tag_name -replace '^v', ''
    $releaseName = $response.name
    $releaseUrl = $response.html_url
    $releaseDate = $response.published_at
    
    Write-Host "GitHub Version: $remoteVersion" -ForegroundColor Green
    Write-Host "Release: $releaseName" -ForegroundColor White
    Write-Host "URL: $releaseUrl" -ForegroundColor Cyan
    Write-Host "Published: $releaseDate" -ForegroundColor Gray
    
} catch [System.Net.Http.HttpRequestException] {
    Write-Host "Error connecting to GitHub API" -ForegroundColor Red
    Write-Host "  Check your internet connection or GitHub token" -ForegroundColor Yellow
    Write-Host "  URL: $apiUrl" -ForegroundColor Gray
    exit 1
} catch {
    Write-Host "Error fetching release: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Compare versions
try {
    $comparison = Compare-TermUIVersion -LocalVersion $localVersion -RemoteVersion $remoteVersion
} catch {
    Write-Host "Version comparison failed: $_" -ForegroundColor Red
    exit 1
}

if ($comparison -eq -1) {
    Write-Host "Update Available!" -ForegroundColor Green
    Write-Host "  Local: $localVersion → Remote: $remoteVersion" -ForegroundColor Yellow
    Write-Host "  Action: Download new release from GitHub" -ForegroundColor Cyan
    
    if ($AutoUpdate) {
        Write-Host ""
        Write-Host "Auto-update enabled - downloading and applying update..." -ForegroundColor Yellow
        # Future: Implement auto-download and extraction
        Write-Host "Auto-update not yet implemented. Please manually download from:" -ForegroundColor Yellow
        Write-Host "  $releaseUrl" -ForegroundColor Cyan
    }
    
    exit 0
    
} elseif ($comparison -eq 0) {
    Write-Host "Up to Date" -ForegroundColor Green
    Write-Host "  Local version matches GitHub ($localVersion)" -ForegroundColor Gray
    exit 0
    
} else {
    Write-Host "Local Version Ahead" -ForegroundColor Magenta
    Write-Host "  Local: $localVersion (ahead of GitHub: $remoteVersion)" -ForegroundColor Yellow
    Write-Host "  This may be a development build" -ForegroundColor Gray
    exit 0
}
