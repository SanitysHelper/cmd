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
