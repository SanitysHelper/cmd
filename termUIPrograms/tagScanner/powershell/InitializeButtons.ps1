#Requires -Version 5.0
# TagScanner Button Initializer - Creates dynamic buttons on startup
Set-StrictMode -Version Latest

$script:tagScannerRoot = Split-Path -Parent $PSScriptRoot
$script:cmdRoot = Split-Path -Parent $script:tagScannerRoot
$script:termUIRoot = Join-Path $script:cmdRoot "termUI"
$script:buttonsRoot = Join-Path $script:tagScannerRoot "buttons\mainUI"
$script:dirsSubmenu = Join-Path $script:buttonsRoot "Directories"

# Clear existing buttons and ensure directory exists
if (Test-Path $script:buttonsRoot) {
    Remove-Item -Path $script:buttonsRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $script:buttonsRoot -Force | Out-Null
New-Item -ItemType Directory -Path $script:dirsSubmenu -Force | Out-Null

# Create main menu button files (.opt files contain descriptions)
"Scan directory and display all audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "Read Mode.opt") -Encoding UTF8
"Select directory and batch edit audio file tags (FLAC and MP3)" | Set-Content -Path (Join-Path $script:buttonsRoot "Write Mode.opt") -Encoding UTF8
"Open _bin folder and show required files checklist" | Set-Content -Path (Join-Path $script:buttonsRoot "Dependencies.opt") -Encoding UTF8

# Create PowerShell scripts for each button
$addDirScript = Join-Path $script:dirsSubmenu "Add Directory.ps1"
# Add Directory option description (.opt)
"Create a new saved directory button" | Set-Content -Path (Join-Path $script:dirsSubmenu "Add Directory.opt") -Encoding UTF8
$readModeScript = Join-Path $script:buttonsRoot "Read Mode.ps1"
$writeModeScript = Join-Path $script:buttonsRoot "Write Mode.ps1"
$depsScript = Join-Path $script:buttonsRoot "Dependencies.ps1"

# Persisted directories list in config
$script:configDir = Join-Path $script:tagScannerRoot "config"
if (-not (Test-Path $script:configDir)) { New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null }
$script:dirsListPath = Join-Path $script:configDir "directories.json"
if (-not (Test-Path $script:dirsListPath)) { "[]" | Set-Content -Path $script:dirsListPath -Encoding UTF8 }

# Add Directory script (creates a new button inside Directories and sets it active)
@'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$configDir = Join-Path $root "config"
$dirsJson = Join-Path $configDir "directories.json"
$scanPath = Join-Path $configDir "scan_directory.txt"
$dirsFolder = Join-Path $root "buttons\mainUI\Directories"

if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
if (-not (Test-Path $dirsFolder)) { New-Item -ItemType Directory -Path $dirsFolder -Force | Out-Null }
if (-not (Test-Path $dirsJson)) { "[]" | Set-Content -Path $dirsJson -Encoding UTF8 }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " ADD DIRECTORY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
$newDir = Read-Host "Enter directory path"
if (-not $newDir -or -not (Test-Path $newDir -PathType Container)) {
    Write-Host "Invalid directory." -ForegroundColor Red
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return
}

# Update directories.json
try {
    $list = Get-Content -Path $dirsJson -Raw | ConvertFrom-Json
    if (-not ($list -contains $newDir)) { $list += $newDir }
    ($list | ConvertTo-Json) | Set-Content -Path $dirsJson -Encoding UTF8
} catch {}

# Create a button for this directory
$safeName = ($newDir -replace '[\\/:*?"<>|]', '_')
$optPath = Join-Path $dirsFolder ("$safeName.opt")
$ps1Path = Join-Path $dirsFolder ("$safeName.ps1")
"Select $newDir as working directory" | Set-Content -Path $optPath -Encoding UTF8
$content = @(
    '$configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"',
    '$scanPath = Join-Path $configDir "scan_directory.txt"',
    ('"' + $newDir + '" | Set-Content -Path $scanPath -Encoding UTF8 -Force'),
    ('Write-Host "Working directory set: ' + $newDir + '" -ForegroundColor Green'),
    'Write-Host "Press any key to continue..." -ForegroundColor DarkGray',
    '$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")'
)
$content | Set-Content -Path $ps1Path -Encoding UTF8

# Also set as current working directory immediately
"$newDir" | Set-Content -Path $scanPath -Encoding UTF8 -Force
Write-Host "Working directory set: $newDir" -ForegroundColor Green
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@ | Set-Content -Path $addDirScript -Encoding UTF8
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
Write-Host "  - Directories (submenu)" -ForegroundColor Cyan
Write-Host "  - Read Mode" -ForegroundColor Cyan
Write-Host "  - Write Mode" -ForegroundColor Cyan
Write-Host "  - Dependencies" -ForegroundColor Cyan

# Generate directory buttons from directories.json
try {
    $dirList = Get-Content -Path $script:dirsListPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($dirList) {
        foreach ($d in $dirList) {
            $safeName = ($d -replace '[\\/:*?"<>|]', '_')
            $optPath = Join-Path $script:dirsSubmenu ("$safeName.opt")
            $ps1Path = Join-Path $script:dirsSubmenu ("$safeName.ps1")
            "Select $d as working directory" | Set-Content -Path $optPath -Encoding UTF8
            $content = @(
                '$configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"',
                '$scanPath = Join-Path $configDir "scan_directory.txt"',
                ('"' + $d + '" | Set-Content -Path $scanPath -Encoding UTF8 -Force'),
                ('Write-Host "Working directory set: ' + $d + '" -ForegroundColor Green'),
                'Write-Host "Press any key to continue..." -ForegroundColor DarkGray',
                '$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")'
            )
            $content | Set-Content -Path $ps1Path -Encoding UTF8
        }
    }
} catch {}

