$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
if (Test-Path $modulePath) {
  . $modulePath
  Start-ReadModeTag -Tag "Description"
} else {
  Write-Host ("ERROR: TagScanner.ps1 module not found at: " + $modulePath) -ForegroundColor Red
}
