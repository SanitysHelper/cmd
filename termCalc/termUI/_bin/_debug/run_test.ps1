# Direct test runner - launches UI and feeds it test keys
param([string]$TestFile = "test1_basic.txt")

$testPath = Join-Path $PSScriptRoot $TestFile
if (-not (Test-Path $testPath)) {
    Write-Host "[ERROR] Test file not found: $testPath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Running test: $TestFile" -ForegroundColor Cyan
Write-Host "[INFO] Test sequence:" -ForegroundColor Gray
Get-Content $testPath | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
Write-Host ""

# Set environment variable to tell UI we're in test mode
$env:TERMUI_TEST_MODE = "1"
$env:TERMUI_TEST_FILE = $testPath

# Launch UI
Set-Location (Split-Path -Parent $PSScriptRoot)
& powershell -NoProfile -ExecutionPolicy Bypass -File "powershell\termUI.ps1"

Write-Host ""
Write-Host "[INFO] Test complete. Check logs in _debug\logs\" -ForegroundColor Green
