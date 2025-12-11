#Requires -Version 5.0
# TagScanner Button Initializer - Creates dynamic buttons on startup
Set-StrictMode -Version Latest

$script:tagScannerRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:cmdRoot = Split-Path -Parent $script:tagScannerRoot
$script:termUIRoot = Join-Path $script:cmdRoot "termUI"
$script:buttonsRoot = Join-Path $script:tagScannerRoot "buttons\mainUI"

# Clear existing buttons and ensure directory exists
if (Test-Path $script:buttonsRoot) {
    Remove-Item -Path $script:buttonsRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $script:buttonsRoot -Force | Out-Null

# Create main menu button files (.opt files contain descriptions)
"Scan directory and display all audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "Read Mode.opt") -Encoding UTF8
"Select directory and batch edit audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "Write Mode.opt") -Encoding UTF8
"Open _bin folder and show required files checklist" | Set-Content -Path (Join-Path $script:buttonsRoot "Dependencies.opt") -Encoding UTF8

# Create PowerShell scripts for each button
$readModeScript = Join-Path $script:buttonsRoot "Read Mode.ps1"
$writeModeScript = Join-Path $script:buttonsRoot "Write Mode.ps1"
$depsScript = Join-Path $script:buttonsRoot "Dependencies.ps1"

# Read Mode script
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
Write-Host "  - Read Mode" -ForegroundColor Cyan
Write-Host "  - Write Mode" -ForegroundColor Cyan
Write-Host "  - Dependencies" -ForegroundColor Cyan

