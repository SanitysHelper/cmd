$configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"
$scanPath = Join-Path $configDir "scan_directory.txt"
"C:\Users\cmand\Music" | Set-Content -Path $scanPath -Encoding UTF8 -Force
Write-Host "Working directory set: C:\Users\cmand\Music" -ForegroundColor Green
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
