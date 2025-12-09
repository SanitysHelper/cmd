# Test script for file watcher functionality
# This simulates manual editing of settings.ini

$testDir = Join-Path (Split-Path -Parent $PSCommandPath) 'automated_testing_environment'
$settingsFile = Join-Path $testDir 'settings.ini'

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  File Watcher Test" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create initial settings
Write-Host "[1] Creating initial settings..." -ForegroundColor Yellow
$initialSettings = @"
# Settings Configuration File
[General]
testKey=initialValue  # Initial test value
"@
$initialSettings | Out-File -FilePath $settingsFile -Encoding UTF8 -Force
Write-Host "    Created settings.ini with testKey=initialValue" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 2: Start Settings Manager in background with input that will show menu multiple times
Write-Host ""
Write-Host "[2] Starting Settings Manager..." -ForegroundColor Yellow
$process = Start-Process powershell -ArgumentList @(
    "-NoExit"
    "-Command"
    "cd '$testDir'; '1`n1`n1`n7`n' | .\run.bat"
) -PassThru
Write-Host "    Settings Manager started (PID: $($process.Id))" -ForegroundColor Green
Start-Sleep -Seconds 3

# Step 3: Manually edit the settings file
Write-Host ""
Write-Host "[3] Simulating external edit to settings.ini..." -ForegroundColor Yellow
$modifiedSettings = @"
# Settings Configuration File
[General]
testKey=externallyModified  # Modified externally!
newKey=addedValue  # Added by external editor
"@
$modifiedSettings | Out-File -FilePath $settingsFile -Encoding UTF8 -Force
Write-Host "    Modified settings.ini externally" -ForegroundColor Green
Write-Host "    - Changed testKey to 'externallyModified'" -ForegroundColor Gray
Write-Host "    - Added newKey='addedValue'" -ForegroundColor Gray

Write-Host ""
Write-Host "[4] Waiting for Settings Manager to detect change..." -ForegroundColor Yellow
Write-Host "    (Check the other window for 'EXTERNAL CHANGE DETECTED' message)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Enter to stop Settings Manager and view results..." -ForegroundColor Yellow
Read-Host

# Stop the process
Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
