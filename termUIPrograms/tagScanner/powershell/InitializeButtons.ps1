#Requires -Version 5.0
# TagScanner Button Initializer - Creates dynamic buttons on startup
Set-StrictMode -Version Latest

$script:tagScannerRoot = Split-Path -Parent $PSScriptRoot
$script:cmdRoot = Split-Path -Parent $script:tagScannerRoot
$script:termUIRoot = Join-Path $script:cmdRoot "termUI"
$script:buttonsRoot = Join-Path $script:tagScannerRoot "buttons\mainUI"

# Clear existing buttons and ensure directory exists
if (Test-Path $script:buttonsRoot) {
    Remove-Item -Path $script:buttonsRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $script:buttonsRoot -Force | Out-Null

# Create main menu button files (.opt files contain descriptions)
# Using numeric prefix to control sort order: 0=first, 1=second, etc.
"Configure the directory to scan for audio files" | Set-Content -Path (Join-Path $script:buttonsRoot "0 - Set Directory.opt") -Encoding UTF8
"Scan directory and display all audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "1 - Read Mode.opt") -Encoding UTF8
"Select directory and batch edit audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "2 - Write Mode.opt") -Encoding UTF8
"Open _bin folder and show required files checklist" | Set-Content -Path (Join-Path $script:buttonsRoot "3 - Dependencies.opt") -Encoding UTF8

# Create PowerShell scripts for each button
$setDirScript = Join-Path $script:buttonsRoot "0 - Set Directory.ps1"
$readModeScript = Join-Path $script:buttonsRoot "1 - Read Mode.ps1"
$writeModeScript = Join-Path $script:buttonsRoot "2 - Write Mode.ps1"
$depsScript = Join-Path $script:buttonsRoot "3 - Dependencies.ps1"

# Set Directory script
@'
$script:configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"
if (-not (Test-Path $script:configDir)) { New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null }
$script:dirPath = Join-Path $script:configDir "scan_directory.txt"

# Load existing path if available
$script:selectedDir = ""
if (Test-Path $script:dirPath) {
    $script:selectedDir = Get-Content -Path $script:dirPath -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
}

# Show current directory or prompt for new one
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SET SCAN DIRECTORY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($script:selectedDir -and (Test-Path $script:selectedDir)) {
    Write-Host "Current directory: $script:selectedDir" -ForegroundColor Green
}

Write-Host "`nSelect new directory? (Y/N): " -ForegroundColor Gray -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    # Load WinForms assembly
    Add-Type -AssemblyName System.Windows.Forms
    
    # Create folder browser dialog
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the directory containing audio files (MP3, FLAC)"
    $dialog.ShowNewFolderButton = $true
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:selectedDir = $dialog.SelectedPath
        
        # Save to config file
        $script:selectedDir | Set-Content -Path $script:dirPath -Encoding UTF8 -Force
        Write-Host "Directory saved: $script:selectedDir" -ForegroundColor Green
    }
    else {
        Write-Host "No directory selected." -ForegroundColor Yellow
    }
}

Write-Host "Press any key to return to menu..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@ | Set-Content -Path $setDirScript -Encoding UTF8
@'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
if (Test-Path $modulePath) {
    . $modulePath
    Start-ReadMode
} else {
    Write-Host "ERROR: TagScanner.ps1 module not found at: $modulePath" -ForegroundColor Red
}
'@ | Set-Content -Path $readModeScript -Encoding UTF8

# Write Mode script
@'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
if (Test-Path $modulePath) {
    . $modulePath
    Start-WriteMode
} else {
    Write-Host "ERROR: TagScanner.ps1 module not found at: $modulePath" -ForegroundColor Red
}
'@ | Set-Content -Path $writeModeScript -Encoding UTF8

# Dependencies script
@'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$bin = Join-Path $root "_bin"
if (-not (Test-Path $bin)) { New-Item -ItemType Directory -Path $bin -Force | Out-Null }
Start-Process explorer.exe $bin
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " REQUIRED FILES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Place these files into: $bin" -ForegroundColor White
Write-Host "  - TagLibSharp.dll (for MP3 tags via TagLib#)" -ForegroundColor Green
Write-Host "  - metaflac.exe    (for FLAC tags)" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "After placing files, run Read Mode or Write Mode." -ForegroundColor Gray
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@ | Set-Content -Path $depsScript -Encoding UTF8

Write-Host "[tagScanner] Buttons initialized successfully:" -ForegroundColor Green
Write-Host "  - Set Directory" -ForegroundColor Cyan
Write-Host "  - Read Mode" -ForegroundColor Cyan
Write-Host "  - Write Mode" -ForegroundColor Cyan
Write-Host "  - Dependencies" -ForegroundColor Cyan

