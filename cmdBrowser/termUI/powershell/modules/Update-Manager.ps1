# Update-Manager.ps1
# Auto-update functionality for termUI
# Checks GitHub for version differences and updates when available

<#
.SYNOPSIS
Manages automatic updates for termUI by checking GitHub for new versions

.DESCRIPTION
Compares local VERSION.json against GitHub repository version
Downloads and installs updates when version numbers differ
Maintains backups of previous versions

.PARAMETER CheckOnly
Only check for updates without installing

.PARAMETER Force
Force update even if versions match

.PARAMETER Silent
Suppress console output (for background checks)
#>

param(
    [switch]$CheckOnly,
    [switch]$Force,
    [switch]$Silent
)

# Configuration
$script:GITHUB_REPO = "SanitysHelper/cmd"
$script:GITHUB_BRANCH = "main"
$script:TERMUI_FOLDER = "termUI"
$script:VERSION_URL = "https://raw.githubusercontent.com/$script:GITHUB_REPO/$script:GITHUB_BRANCH/$script:TERMUI_FOLDER/VERSION.json"
$script:DOWNLOAD_URL = "https://github.com/$script:GITHUB_REPO/archive/refs/heads/$script:GITHUB_BRANCH.zip"

# Paths
$script:scriptRoot = if ($PSScriptRoot) { 
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot) 
} else { 
    Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) 
}
$script:versionFile = Join-Path $script:scriptRoot "VERSION.json"
$script:debugPath = Join-Path $script:scriptRoot "_debug"
$script:backupPath = Join-Path $script:debugPath "backups"
$script:logsPath = Join-Path $script:debugPath "logs"
$script:updateLog = Join-Path $script:logsPath "update.log"

# Ensure directories exist
if (-not (Test-Path $script:logsPath)) {
    New-Item -ItemType Directory -Path $script:logsPath -Force | Out-Null
}
if (-not (Test-Path $script:backupPath)) {
    New-Item -ItemType Directory -Path $script:backupPath -Force | Out-Null
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $script:updateLog -Value $logMessage -Encoding UTF8
    
    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host "[$Level] $Message" -ForegroundColor Red }
            "WARN"  { Write-Host "[$Level] $Message" -ForegroundColor Yellow }
            "SUCCESS" { Write-Host "[$Level] $Message" -ForegroundColor Green }
            default { Write-Host "[$Level] $Message" }
        }
    }
}

# Stop processes that may lock files (InputHandler)
function Stop-ConflictingProcesses {
    try {
        $procs = Get-Process -Name InputHandler -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Log "Stopping InputHandler processes before update..." "WARN"
            $procs | ForEach-Object {
                try {
                    Stop-Process -Id $_.Id -Force -ErrorAction Stop
                    Write-Log "Stopped InputHandler pid=$($_.Id)" "SUCCESS"
                }
                catch {
                    Write-Log "Failed to stop InputHandler pid=$($_.Id): $_" "WARN"
                }
            }
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Log "Error checking conflicting processes: $_" "WARN"
    }
}

# Get current local version
function Get-LocalVersion {
    try {
        if (-not (Test-Path $script:versionFile)) {
            Write-Log "VERSION.json not found locally" "WARN"
            return $null
        }
        
        $versionContent = Get-Content $script:versionFile -Raw | ConvertFrom-Json
        Write-Log "Local version: $($versionContent.version)"
        return $versionContent.version
    }
    catch {
        Write-Log "Failed to read local VERSION.json: $_" "ERROR"
        return $null
    }
}

# Get remote version from GitHub
function Get-RemoteVersion {
    try {
        Write-Log "Checking GitHub for latest version..."
        
        # Use Invoke-WebRequest to fetch VERSION.json from GitHub
        $response = Invoke-WebRequest -Uri $script:VERSION_URL -UseBasicParsing -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            $remoteVersion = ($response.Content | ConvertFrom-Json).version
            Write-Log "Remote version: $remoteVersion"
            return $remoteVersion
        }
        else {
            Write-Log "Failed to fetch remote version: HTTP $($response.StatusCode)" "ERROR"
            return $null
        }
    }
    catch {
        Write-Log "Error fetching remote version: $_" "ERROR"
        return $null
    }
}

# Compare version numbers
function Compare-Versions {
    param(
        [string]$Local,
        [string]$Remote
    )
    
    if ([string]::IsNullOrWhiteSpace($Local) -or [string]::IsNullOrWhiteSpace($Remote)) {
        return $false
    }
    
    # Parse version strings (e.g., "1.1.0" -> @(1, 1, 0))
    try {
        $localParts = $Local -split '\.' | ForEach-Object { [int]$_ }
        $remoteParts = $Remote -split '\.' | ForEach-Object { [int]$_ }
        
        # Compare major, minor, patch
        for ($i = 0; $i -lt [Math]::Max($localParts.Count, $remoteParts.Count); $i++) {
            $localPart = if ($i -lt $localParts.Count) { $localParts[$i] } else { 0 }
            $remotePart = if ($i -lt $remoteParts.Count) { $remoteParts[$i] } else { 0 }
            
            if ($remotePart -gt $localPart) {
                Write-Log "Update available: $Local -> $Remote" "SUCCESS"
                return $true
            }
            elseif ($remotePart -lt $localPart) {
                Write-Log "Local version is newer than remote" "WARN"
                return $false
            }
        }
        
        Write-Log "Versions are identical: $Local"
        return $false
    }
    catch {
        Write-Log "Error comparing versions: $_" "ERROR"
        return $false
    }
}

# Create backup of current version
function Backup-CurrentVersion {
    param(
        [string]$Version
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $backupFolder = Join-Path $script:backupPath "termUI_v${Version}_$timestamp"
        
        Write-Log "Creating backup: $backupFolder"
        
        # Copy entire termUI folder except _debug
        $filesToBackup = Get-ChildItem -Path $script:scriptRoot -Recurse | 
            Where-Object { $_.FullName -notlike "*\_debug\*" }
        
        foreach ($file in $filesToBackup) {
            $relativePath = $file.FullName.Substring($script:scriptRoot.Length + 1)
            $destPath = Join-Path $backupFolder $relativePath
            
            if ($file.PSIsContainer) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
            else {
                $destDir = Split-Path -Parent $destPath
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $file.FullName -Destination $destPath -Force
            }
        }
        
        Write-Log "Backup created successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

# Download and install update
function Install-Update {
    param(
        [string]$LocalVersion,
        [string]$RemoteVersion
    )
    
    try {
        Write-Log "Starting update from $LocalVersion to $RemoteVersion"
        
        # Step 0: Stop conflicting processes
        Stop-ConflictingProcesses
        
        # Step 1: Create backup
        if (-not (Backup-CurrentVersion -Version $LocalVersion)) {
            Write-Log "Cannot proceed without backup" "ERROR"
            return $false
        }
        
        # Step 2: Download ZIP from GitHub
        Write-Log "Downloading update from GitHub..."
        $tempZip = Join-Path $script:debugPath "termUI_update.zip"
        $tempExtract = Join-Path $script:debugPath "termUI_update_temp"
        
        try {
            Invoke-WebRequest -Uri $script:DOWNLOAD_URL -OutFile $tempZip -UseBasicParsing -TimeoutSec 60
            Write-Log "Download complete"
        }
        catch {
            Write-Log "Download failed: $_" "ERROR"
            return $false
        }
        
        # Step 3: Extract archive
        Write-Log "Extracting update..."
        try {
            if (Test-Path $tempExtract) {
                Remove-Item -Path $tempExtract -Recurse -Force
            }
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
            Write-Log "Extraction complete"
        }
        catch {
            Write-Log "Extraction failed: $_" "ERROR"
            Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
            return $false
        }
        
        # Step 4: Copy new files (preserve _debug folder)
        Write-Log "Installing updated files..."
        $sourceFolder = Join-Path $tempExtract "cmd-$script:GITHUB_BRANCH\$script:TERMUI_FOLDER"
        
        if (-not (Test-Path $sourceFolder)) {
            Write-Log "Source folder not found in archive: $sourceFolder" "ERROR"
            Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            return $false
        }
        
        # Copy all files except _debug
        $newFiles = Get-ChildItem -Path $sourceFolder -Recurse
        $retryCopyAttempted = $false
        foreach ($file in $newFiles) {
            $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)
            
            # Skip _debug folder
            if ($relativePath -like "_debug\*" -or $relativePath -eq "_debug") {
                continue
            }
            
            $destPath = Join-Path $script:scriptRoot $relativePath
            
            if ($file.PSIsContainer) {
                if (-not (Test-Path $destPath)) {
                    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
                }
            }
            else {
                $destDir = Split-Path -Parent $destPath
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                try {
                    Copy-Item -Path $file.FullName -Destination $destPath -Force
                }
                catch {
                    Write-Log "File in use or copy failed for: $relativePath. Error: $_" "WARN"
                    if (-not $retryCopyAttempted) {
                        $retryCopyAttempted = $true
                        Write-Log "Retrying copy after 3 seconds..." "WARN"
                        Start-Sleep -Seconds 3
                        try {
                            Copy-Item -Path $file.FullName -Destination $destPath -Force
                        }
                        catch {
                            Write-Log "Retry failed for: $relativePath. Please close any running termUI instances and re-run update." "ERROR"
                            throw
                        }
                    }
                    else {
                        throw
                    }
                }
            }
        }
        
        Write-Log "Files installed successfully" "SUCCESS"
        
        # Step 5: Cleanup
        Write-Log "Cleaning up temporary files..."
        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Log "Update completed successfully: $LocalVersion -> $RemoteVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Update installation failed: $_" "ERROR"
        return $false
    }
}

# Main update check logic
function Start-UpdateCheck {
    Write-Log "=== termUI Update Check Started ==="
    
    # Get versions
    $localVersion = Get-LocalVersion
    $remoteVersion = Get-RemoteVersion
    
    if ($null -eq $localVersion) {
        Write-Log "Cannot proceed without local version" "ERROR"
        return $false
    }
    
    if ($null -eq $remoteVersion) {
        Write-Log "Cannot reach GitHub, skipping update check" "WARN"
        return $false
    }
    
    # Compare versions
    $updateAvailable = Compare-Versions -Local $localVersion -Remote $remoteVersion
    
    if ($Force) {
        Write-Log "Force flag set, updating regardless of version" "WARN"
        $updateAvailable = $true
    }
    
    if (-not $updateAvailable) {
        Write-Log "No update needed" "SUCCESS"
        return $false
    }
    
    if ($CheckOnly) {
        Write-Log "Check-only mode, skipping installation" "INFO"
        if (-not $Silent) {
            Write-Host ""
            Write-Host "Update available: $localVersion -> $remoteVersion" -ForegroundColor Cyan
            Write-Host "Run with -Force to install update" -ForegroundColor Cyan
        }
        return $true
    }
    
    # Prompt user for confirmation (unless silent)
    if (-not $Silent) {
        Write-Host ""
        Write-Host "Update available: $localVersion -> $remoteVersion" -ForegroundColor Cyan
        Write-Host ""
        $response = Read-Host "Install update? (Y/N)"
        
        if ($response -notmatch '^[Yy]') {
            Write-Log "Update declined by user"
            return $false
        }
    }
    
    # Install update
    $success = Install-Update -LocalVersion $localVersion -RemoteVersion $remoteVersion
    
    if ($success) {
        if (-not $Silent) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  Update installed successfully!" -ForegroundColor Green
            Write-Host "  Version: $localVersion -> $remoteVersion" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Restart termUI to use the new version" -ForegroundColor Yellow
        }
    }
    
    Write-Log "=== Update Check Completed ==="
    return $success
}

# Run if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-UpdateCheck
}
