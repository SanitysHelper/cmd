# Test Print Program - Demonstrates Settings Manager Usage
# This program reads settings and prints values based on configuration

param()

# Paths
$ScriptDir = Split-Path -Parent $PSCommandPath
# Go up one level from _debug to get to settings folder
$SettingsDir = Split-Path -Parent $ScriptDir
$SettingsFile = Join-Path $SettingsDir 'settings.ini'

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "         TEST PRINT PROGRAM                    " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Load settings
if (-not (Test-Path $SettingsFile)) {
    Write-Host ""
    Write-Host "[ERROR] Settings file not found: $SettingsFile" -ForegroundColor Red
    Write-Host "[INFO] Please create settings first using Settings Manager." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[INFO] Loading settings from: $SettingsFile" -ForegroundColor Green

# Parse settings.ini
$settings = @{}
$currentSection = 'General'

Get-Content $SettingsFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^\[(.+)\]$') {
        $currentSection = $matches[1]
        if (-not $settings.ContainsKey($currentSection)) {
            $settings[$currentSection] = @{}
        }
    } elseif ($line -match '^([^=]+)=(.+?)(?:\s*#.*)?$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if (-not $settings.ContainsKey($currentSection)) {
            $settings[$currentSection] = @{}
        }
        $settings[$currentSection][$key] = $value
    }
}

# Look for printVal and printAmount settings
$printVal = $null
$printAmount = 1

if ($settings.ContainsKey('General')) {
    if ($settings['General'].ContainsKey('printVal')) {
        $printVal = $settings['General']['printVal']
        Write-Host "[INFO] Found printVal = '$printVal'" -ForegroundColor Green
    }
    
    if ($settings['General'].ContainsKey('printAmount')) {
        $printAmount = [int]$settings['General']['printAmount']
        Write-Host "[INFO] Found printAmount = $printAmount" -ForegroundColor Green
    }
}

# Validate settings
$missingSettings = @()
if ($null -eq $printVal) {
    $missingSettings += 'printVal'
}

if ($missingSettings.Count -gt 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  MISSING REQUIRED SETTINGS" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This test program requires the following settings:" -ForegroundColor Yellow
    Write-Host ""
    
    if ($missingSettings -contains 'printVal') {
        Write-Host "  [MISSING] printVal" -ForegroundColor Red
        Write-Host "    Description: The text value to print" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  HOW TO ADD THESE SETTINGS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "From Settings Manager main menu:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Select [3] Add new setting" -ForegroundColor Green
    Write-Host "  2. When prompted for section, type: General" -ForegroundColor Green
    Write-Host "  3. When prompted for key, type: printVal" -ForegroundColor Green
    Write-Host "  4. When prompted for value, type: Hello from test program!" -ForegroundColor Green
    Write-Host "  5. When prompted for description, type: Text to print in test" -ForegroundColor Green
    Write-Host ""
    Write-Host "Optional setting (will default to 1 if not set):" -ForegroundColor Yellow
    Write-Host "  * printAmount - Number of times to print (integer)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Execute print operation
Write-Host ""
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "EXECUTING PRINT OPERATION" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

for ($i = 1; $i -le $printAmount; $i++) {
    Write-Host ""
    Write-Host "[$i/$printAmount] $printVal" -ForegroundColor White
}

Write-Host ""
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "[SUCCESS] Print operation completed!" -ForegroundColor Green
Write-Host "Total prints: $printAmount" -ForegroundColor Gray
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host ""

exit 0
