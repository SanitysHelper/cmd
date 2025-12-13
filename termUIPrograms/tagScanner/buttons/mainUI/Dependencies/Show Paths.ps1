$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
if (Test-Path $modulePath) {
  . $modulePath
  $ok = Test-Dependencies
  Write-Host "`n========================================" -ForegroundColor Cyan
  Write-Host " DEPENDENCY PATHS" -ForegroundColor Green
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host ("Status: " + ($ok ? "OK" : "Missing")) -ForegroundColor ($ok ? "Green" : "Yellow")
  Write-Host ("metaflacCmd: " + $script:metaflacCmd) -ForegroundColor White
  $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
  $bin = Join-Path $root "_bin"
  Write-Host ("TagLibSharp.dll: " + (Join-Path $bin "TagLibSharp.dll")) -ForegroundColor White
  Write-Host ("libflac.dll: " + (Join-Path $bin "libflac.dll")) -ForegroundColor White
  Write-Host "Press any key to continue..." -ForegroundColor DarkGray
  $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
  Write-Host ("ERROR: TagScanner.ps1 module not found at: " + $modulePath) -ForegroundColor Red
}