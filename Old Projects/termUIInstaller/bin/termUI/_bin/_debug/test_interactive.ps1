# Interactive test - allows real keyboard input
# Press Q to quit

Write-Host "=== Interactive termUI Test ===" -ForegroundColor Cyan
Write-Host "Use arrow keys to navigate, Enter to select, Q to quit" -ForegroundColor Yellow
Write-Host ""

$env:TERMUI_TEST_MODE = $null
$env:TERMUI_TEST_FILE = $null

Set-Location (Split-Path -Parent $PSScriptRoot)
& .\run.bat

Write-Host ""
Write-Host "Interactive test complete." -ForegroundColor Green
