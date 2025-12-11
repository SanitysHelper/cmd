#Requires -Version 5.0
# TagScanner Button Initializer - Creates dynamic buttons on startup
Set-StrictMode -Version Latest

$script:termUIRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:buttonsRoot = Join-Path $script:termUIRoot "buttons\mainUI"

# Import termUI button library
. (Join-Path $script:termUIRoot "powershell\modules\TermUIButtonLibrary.ps1")

# Clear existing buttons and create menu structure
Clear-TermUIButtons -TermUIRoot $script:termUIRoot

# Create main menu buttons
Add-TermUIButton -TermUIRoot $script:termUIRoot -Path "Read Mode.opt" -Description "Scan directory and display all audio file tags (FLAC and MP3)"
Add-TermUIButton -TermUIRoot $script:termUIRoot -Path "Write Mode.opt" -Description "Select directory and batch edit audio file tags (FLAC and MP3)"
Add-TermUIButton -TermUIRoot $script:termUIRoot -Path "Dependencies.opt" -Description "Open _bin folder and show required files checklist"

# Create PowerShell scripts for each button
$readModeScript = Join-Path $script:buttonsRoot "Read Mode.ps1"
$writeModeScript = Join-Path $script:buttonsRoot "Write Mode.ps1"
$depsScript = Join-Path $script:buttonsRoot "Dependencies.ps1"

# Read Mode script
@'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
. $modulePath
Start-ReadMode
'@ | Set-Content -Path $readModeScript -Encoding UTF8

# Write Mode script
@'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
. $modulePath
Start-WriteMode
'@ | Set-Content -Path $writeModeScript -Encoding UTF8

Write-Host "[tagScanner] Menu buttons and scripts initialized" -ForegroundColor Green

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
