$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$validPath = Join-Path $root "_bin/proxies_valid.txt"
$exports = Join-Path $root "_debug/exports"
if (-not (Test-Path $exports)) { New-Item -ItemType Directory -Path $exports -Force | Out-Null }
if (-not (Test-Path $validPath)) { Write-Host "No validated proxies to export." -ForegroundColor Yellow; return }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$target = Join-Path $exports ("proxies_valid_" + $ts + ".txt")
Copy-Item -Path $validPath -Destination $target -Force
Write-Host "Exported: $target" -ForegroundColor Green
