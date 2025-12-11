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

# Update directories.json - ensure proper array handling
try {
    $content = Get-Content -Path $dirsJson -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content) -or $content -eq '[]') {
        $list = @()
    } else {
        $parsed = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -is [array]) {
            $list = $parsed
        } else {
            $list = @($parsed)
        }
    }
    if (-not ($list -contains $newDir)) { $list += $newDir }
    ($list | ConvertTo-Json) | Set-Content -Path $dirsJson -Encoding UTF8
} catch {}

# Create a button for this directory using safe path as filename
$safePath = ($newDir -replace '\\', '_' -replace ':', '')
$optPath = Join-Path $dirsFolder ("$safePath.opt")
$ps1Path = Join-Path $dirsFolder ("$safePath.ps1")
"$newDir" | Set-Content -Path $optPath -Encoding UTF8
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
Write-Host "The new directory has been added." -ForegroundColor Cyan


Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
