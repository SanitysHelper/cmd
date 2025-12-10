# termUI Standalone Launcher
# Single script that downloads and runs termUI from GitHub
# Can be compiled to EXE using ps2exe or run as PS1

param(
    [switch]$Version,
    [switch]$Changelog,
    [switch]$CheckUpdate,
    [switch]$Update
)

$ErrorActionPreference = "Stop"

# Configuration
$GITHUB_REPO = "SanitysHelper/cmd"
$GITHUB_BRANCH = "main"
$GITHUB_RAW = "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/termUI"
$LOCAL_CACHE = "$env:APPDATA\termUI"

function Ensure-Cache {
    if (-not (Test-Path $LOCAL_CACHE)) {
        New-Item -ItemType Directory -Path $LOCAL_CACHE -Force | Out-Null
    }
}

function Download-File {
    param(
        [string]$RemotePath,
        [string]$LocalPath
    )
    
    try {
        $url = "$GITHUB_RAW/$RemotePath"
        $dir = Split-Path -Parent $LocalPath
        
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Write-Host "[INFO] Downloading: $RemotePath" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing -TimeoutSec 30
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to download $RemotePath`: $_" -ForegroundColor Red
        return $false
    }
}

function Sync-Files {
    Ensure-Cache
    
    $requiredFiles = @(
        'VERSION.json'
        'settings.ini'
        'powershell/termUI.ps1'
        'powershell/InputHandler.ps1'
        'powershell/modules/Logging.ps1'
        'powershell/modules/Settings.ps1'
        'powershell/modules/MenuBuilder.ps1'
        'powershell/modules/InputBridge.ps1'
        'powershell/modules/VersionManager.ps1'
        'powershell/modules/Update-Manager.ps1'
        'powershell/modules/TermUIButtonLibrary.ps1'
        'powershell/modules/TermUIFunctionLibrary.ps1'
    )
    
    Write-Host ""
    Write-Host "Syncing termUI files from GitHub..." -ForegroundColor Yellow
    Write-Host ""
    
    $downloaded = 0
    foreach ($file in $requiredFiles) {
        $localPath = Join-Path $LOCAL_CACHE $file
        
        # Only download if file doesn't exist or is missing
        if (-not (Test-Path $localPath)) {
            if (Download-File -RemotePath $file -LocalPath $localPath) {
                $downloaded++
            }
        }
    }
    
    if ($downloaded -gt 0) {
        Write-Host ""
        Write-Host "[SUCCESS] Downloaded $downloaded files" -ForegroundColor Green
    } else {
        Write-Host "[INFO] All files already cached" -ForegroundColor Gray
    }
}

function Get-LocalVersion {
    try {
        $versionFile = Join-Path $LOCAL_CACHE "VERSION.json"
        if (Test-Path $versionFile) {
            $version = (Get-Content $versionFile -Raw | ConvertFrom-Json).version
            return $version
        }
    }
    catch {}
    return "unknown"
}

function Get-RemoteVersion {
    try {
        $url = "$GITHUB_RAW/VERSION.json"
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $version = ($content.Content | ConvertFrom-Json).version
        return $version
    }
    catch {
        return $null
    }
}

function Show-Version {
    $version = Get-LocalVersion
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "termUI v$version (Standalone)" -ForegroundColor Green
    Write-Host "GitHub: https://github.com/$GITHUB_REPO" -ForegroundColor Gray
    Write-Host "Branch: $GITHUB_BRANCH" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Changelog {
    Ensure-Cache
    $versionFile = Join-Path $LOCAL_CACHE "VERSION.json"
    
    if (-not (Test-Path $versionFile)) {
        Sync-Files
    }
    
    try {
        $content = Get-Content $versionFile -Raw | ConvertFrom-Json
        Write-Host ""
        Write-Host "=== termUI Changelog ===" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($entry in $content.changelog) {
            Write-Host "Version $($entry.version) - $($entry.date)" -ForegroundColor Green
            foreach ($change in $entry.changes) {
                Write-Host "  * $change" -ForegroundColor White
            }
            Write-Host ""
        }
    }
    catch {
        Write-Host "[ERROR] Failed to read changelog" -ForegroundColor Red
    }
}

function Start-TermUI {
    Sync-Files
    
    $termUIScript = Join-Path $LOCAL_CACHE "powershell\termUI.ps1"
    if (-not (Test-Path $termUIScript)) {
        Write-Host "[ERROR] Failed to load termUI script" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Starting termUI..." -ForegroundColor Green
    Write-Host ""
    
    & $termUIScript @args
}

# Main logic
if ($Version) {
    Show-Version
    exit 0
}

if ($Changelog) {
    Show-Changelog
    exit 0
}

if ($CheckUpdate -or $Update) {
    Sync-Files
    
    $localVer = Get-LocalVersion
    $remoteVer = Get-RemoteVersion
    
    if ($remoteVer -and $localVer -ne $remoteVer) {
        Write-Host ""
        Write-Host "Update available: $localVer -> $remoteVer" -ForegroundColor Yellow
        Write-Host ""
        
        if ($Update) {
            Write-Host "Installing update..." -ForegroundColor Cyan
            Remove-Item (Join-Path $LOCAL_CACHE "*") -Recurse -Force -ErrorAction SilentlyContinue
            Sync-Files
            Write-Host "[SUCCESS] Update complete!" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] No update available" -ForegroundColor Gray
    }
    exit 0
}

# Default: start termUI
Start-TermUI @args
