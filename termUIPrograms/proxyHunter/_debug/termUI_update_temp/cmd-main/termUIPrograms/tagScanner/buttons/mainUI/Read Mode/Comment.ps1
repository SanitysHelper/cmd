$ErrorActionPreference = "Stop"

# Load TagScanner module
$scriptRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))))
$modulePath = Join-Path $scriptRoot "powershell/modules/TagScanner.ps1"
if (-not (Test-Path $modulePath)) { Write-Host "TagScanner module missing: $modulePath" -ForegroundColor Red; exit 1 }
. $modulePath

Start-ReadModeDescriptionComment
