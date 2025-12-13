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
# Always check termUI framework (not program-specific)
$script:VERSION_URL = "https://raw.githubusercontent.com/$script:GITHUB_REPO/$script:GITHUB_BRANCH/termUI/VERSION.json"
$script:DOWNLOAD_URL = "https://github.com/$script:GITHUB_REPO/archive/refs/heads/$script:GITHUB_BRANCH.zip"

# Paths: determined from calling script or module location
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

# Load settings to control backup behavior
try {
    $settingsModule = Join-Path $script:scriptRoot "powershell/modules/Settings.ps1"
    if (Test-Path $settingsModule) {
        . $settingsModule
        $settingsIni = Join-Path $script:scriptRoot "settings.ini"
        Initialize-Settings -SettingsPath $settingsIni
    }
}
catch {
    # If settings fail to load, continue with defaults (debug_mode=false)
}

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
    
    # Write to log with retry logic for file locks
    $retries = 3
    while ($retries -gt 0) {
        try {
            Add-Content -Path $script:updateLog -Value $logMessage -Encoding UTF8 -ErrorAction Stop
            break
        }
        catch {
            $retries--
            if ($retries -eq 0) {
                # Silently fail - don't break update process for logging issues
                break
            }
            Start-Sleep -Milliseconds 100
        }
    }
    
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
        
        # Use robocopy for faster backup (excludes _debug and _bin)
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        
        $robocopyArgs = @(
            $script:scriptRoot,
            $backupFolder,
            '/E',
            '/XD', '_debug', '_bin',
            '/NFL',
            '/NDL', 
            '/NJH',
            '/NJS'
        )
        
        $null = & robocopy @robocopyArgs 2>&1
        $robocopyExitCode = $LASTEXITCODE
        
        # Robocopy exit codes: 0-7 are success, 8+ are errors
        if ($robocopyExitCode -ge 8) {
            Write-Log "Backup failed with robocopy exit code $robocopyExitCode" "ERROR"
            return $false
        }
        
        Write-Log "Backup created successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

# Clean up temporary download files
function Remove-UpdateTemporaryFiles {
    param(
        [string]$TempZip,
        [string]$TempExtract
    )
    
    try {
        if (Test-Path $TempZip) {
            Write-Log "Removing temporary ZIP: $TempZip" "INFO"
            Remove-Item -Path $TempZip -Force -ErrorAction Stop
            Write-Log "Temporary ZIP removed successfully" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to remove temporary ZIP: $_" "WARN"
    }
    
    try {
        if (Test-Path $TempExtract) {
            Write-Log "Removing temporary extraction folder: $TempExtract" "INFO"
            Remove-Item -Path $TempExtract -Recurse -Force -ErrorAction Stop
            Write-Log "Temporary extraction folder removed successfully" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to remove temporary extraction folder: $_" "WARN"
    }
}

# Download and install update
function Install-Update {
    param(
        [string]$LocalVersion,
        [string]$RemoteVersion
    )
    
    # Initialize temp paths at function scope
    $tempZip = Join-Path $script:debugPath "termUI_update.zip"
    $tempExtract = Join-Path $script:debugPath "termUI_update_temp"
    
    try {
        Write-Log "Starting update from $LocalVersion to $RemoteVersion"
        
        # Step 0: Stop conflicting processes
        Stop-ConflictingProcesses
        
        # Step 1: Create backup (only when debug_mode is enabled)
        $shouldBackup = $false
        try {
            if ($script:settings -and $script:settings.General -and $script:settings.General.debug_mode) {
                $shouldBackup = $true
            }
        } catch { }

        if ($shouldBackup) {
            if (-not (Backup-CurrentVersion -Version $LocalVersion)) {
                Write-Log "Cannot proceed without backup" "ERROR"
                return $false
            }
        } else {
            Write-Log "Skipping backup (debug_mode=false)" "INFO"
        }
        
        # Step 2: Download ZIP from GitHub (streaming for maximum speed)
        Write-Log "Downloading update from GitHub..."
        $tempZip = Join-Path $script:debugPath "termUI_update.zip"
        $tempExtract = Join-Path $script:debugPath "termUI_update_temp"
        
        try {
            Add-Type -AssemblyName System.Net.Http
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls
            $handler = New-Object System.Net.Http.HttpClientHandler
            $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
            $client = [System.Net.Http.HttpClient]::new($handler)
            $client.Timeout = [TimeSpan]::FromMinutes(5)
            $request = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Get, $script:DOWNLOAD_URL)
            $request.Headers.UserAgent.ParseAdd("termUI-Updater")
            $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            $response.EnsureSuccessStatusCode() | Out-Null
            $stream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::Open($tempZip, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $buffer = New-Object byte[] 81920
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $fileStream.Write($buffer, 0, $read)
            }
            $fileStream.Dispose(); $stream.Dispose(); $response.Dispose(); $client.Dispose(); $handler.Dispose()
            Write-Log "Download complete"
        }
        catch {
            Write-Log "Download failed: $_" "ERROR"
            Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
            return $false
        }
        
        # Step 3: Extract archive (using .NET for 10x faster extraction)
        Write-Log "Extracting update..."
        try {
            if (Test-Path $tempExtract) {
                Remove-Item -Path $tempExtract -Recurse -Force
            }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempExtract)
            Write-Log "Extraction complete"
        }
        catch {
            Write-Log "Extraction failed: $_" "ERROR"
            Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
            return $false
        }
        
        # Step 4: Copy new files (preserve _debug folder)
        Write-Log "Installing updated files..."
        $sourceFolder = Join-Path $tempExtract "cmd-$script:GITHUB_BRANCH\$script:TERMUI_FOLDER"
        
        if (-not (Test-Path $sourceFolder)) {
            Write-Log "Source folder not found in archive: $sourceFolder" "ERROR"
            Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
            return $false
        }
        
        # Use robocopy for 10x faster file copying (excludes _debug, _bin, buttons, and .exe files)
        try {
            # Robocopy: /E=copy subdirs including empty, /XD=exclude dirs, /XF=exclude files, /R:2=2 retries, /W:3=3sec wait, /NJH /NJS /NDL=minimal output
            $robocopyArgs = @(
                $sourceFolder,
                $script:scriptRoot,
                '/E',
                '/XD', '_debug', '_bin', 'buttons',
                '/XF', '*.exe',
                '/R:0',
                '/W:0',
                '/NFL',
                '/NDL',
                '/NJH',
                '/NJS'
            )
            
            $robocopyOutput = & robocopy @robocopyArgs 2>&1
            $robocopyExitCode = $LASTEXITCODE
            
            # Robocopy exit codes: 0-7 are success, 8+ are errors
            # 0=no files copied, 1=files copied, 2=extra files/dirs, 3=mismatched, 4-7=combinations
            if ($robocopyExitCode -ge 8) {
                # Fallback to recursive copy using PowerShell (preserves directory structure)
                Write-Log "Falling back to recursive directory copy..." "WARN"
                try {
                    $excludedDirs = @('_debug', '_bin', 'buttons')
                    $items = Get-ChildItem -Path $sourceFolder -Recurse | Where-Object {
                        $relativePath = $_.FullName.Substring($sourceFolder.Length).TrimStart('\')
                        $pathParts = $relativePath -split '\\'
                        $isExcluded = $false
                        foreach ($part in $pathParts) {
                            if ($excludedDirs -contains $part) {
                                $isExcluded = $true
                                break
                            }
                        }
                        # Also exclude .exe files (running executable cannot be replaced)
                        if ($_.Extension -eq '.exe') {
                            $isExcluded = $true
                        }
                        -not $isExcluded
                    }
                    foreach ($item in $items) {
                        $relativePath = $item.FullName.Substring($sourceFolder.Length).TrimStart('\')
                        $destination = Join-Path $script:scriptRoot $relativePath
                        
                        if ($item.PSIsContainer) {
                            # Create directory if it doesn't exist
                            if (-not (Test-Path $destination)) {
                                $null = New-Item -ItemType Directory -Path $destination -Force
                            }
                        }
                        else {
                            # Copy file (create parent directory if needed)
                            $parentDir = Split-Path -Parent $destination
                            if (-not (Test-Path $parentDir)) {
                                $null = New-Item -ItemType Directory -Path $parentDir -Force
                            }
                            try {
                                Copy-Item -Path $item.FullName -Destination $destination -Force -ErrorAction Stop
                            }
                            catch {
                                # Silently skip files that can't be copied (like running executables)
                                if ($_.Exception.Message -notlike "*being used by another process*") {
                                    $errMsg = $_.Exception.Message
                                    Write-Log "Failed to copy $relativePath`: $errMsg" "WARN"
                                }
                            }
                        }
                    }
                    Write-Log "Fallback copy completed with directory structure preserved" "SUCCESS"
                }
                catch {
                    Write-Log "Fallback copy failed: $_" "ERROR"
                    throw
                }
            }
            else {
                Write-Log "Files installed successfully (robocopy exit code: $robocopyExitCode)" "SUCCESS"
            }
        }
        catch {
            Write-Log "File installation error: $_" "ERROR"
            throw
        }
        
        # Step 5: Cleanup
        Write-Log "Cleaning up temporary files..."
        Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
        
        Write-Log "Update completed successfully: $LocalVersion -> $RemoteVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Update installation failed: $_" "ERROR"
        Write-Log "Performing cleanup of downloaded files due to failure..." "WARN"
        Remove-UpdateTemporaryFiles -TempZip $tempZip -TempExtract $tempExtract
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
            Write-Host "Launching updated termUI..." -ForegroundColor Cyan
        }
        
        Write-Log "=== Update Check Completed ==="
        
        # Auto-launch termUI after successful update
        try {
            $termUIExe = Join-Path $script:scriptRoot "termUI.exe"
            if (Test-Path $termUIExe) {
                Start-Process -FilePath $termUIExe -WorkingDirectory $script:scriptRoot
                Write-Log "Launched updated termUI" "SUCCESS"
            }
            else {
                Write-Log "termUI.exe not found, skipping auto-launch" "WARN"
            }
        }
        catch {
            Write-Log "Failed to launch termUI: $_" "WARN"
        }
    }
    else {
        Write-Log "=== Update Check Completed ==="
    }
    
    return $success
}

# Run if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-UpdateCheck
}
