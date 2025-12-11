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
