#!/usr/bin/env powershell
#Requires -Version 5.0
# Comprehensive termUI Testing Suite - Final Validation

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n================================================================================" -ForegroundColor Magenta
Write-Host "  COMPREHENSIVE termUI TESTING SUITE - FINAL VALIDATION" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

$pass = 0
$fail = 0

# TEST 1: Version flag
Write-Host "`n[TEST 1] Version flag" -ForegroundColor Cyan
$out = & powershell -ExecutionPolicy Bypass -File ".\powershell\termUI.ps1" --version 2>&1
if ($out -match "termUI v") {
    Write-Host "  [PASS] Version output correct" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [FAIL] Version output incorrect" -ForegroundColor Red
    $fail++
}

# TEST 2: Input Handler exists
Write-Host "`n[TEST 2] Input Handler" -ForegroundColor Cyan
if (Test-Path ".\powershell\InputHandler.ps1") {
    Write-Host "  [PASS] InputHandler.ps1 exists" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [FAIL] InputHandler.ps1 missing" -ForegroundColor Red
    $fail++
}

# TEST 3: Test navigation
Write-Host "`n[TEST 3] Navigation test" -ForegroundColor Cyan
$out = powershell -ExecutionPolicy Bypass -Command {
    cd "c:\Users\cmand\OneDrive\Desktop\cmd\termUI"
    $env:TERMUI_TEST_MODE = "1"
    $env:TERMUI_TEST_FILE = "$PWD\_debug\test_navigation_simple.txt"
    . .\powershell\termUI.ps1
} 2>&1
if ($out -match "mainUI/TextInput" -and $out -match "NumberA") {
    Write-Host "  [PASS] Navigation working" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [FAIL] Navigation failed" -ForegroundColor Red
    $fail++
}

# TEST 4: Log files
Write-Host "`n[TEST 4] Log files creation" -ForegroundColor Cyan
$logDir = "_bin\_debug\logs"
$logs = @("input.log", "important.log", "menu-frame.log", "input-timing.log")
foreach ($log in $logs) {
    if (Test-Path (Join-Path $logDir $log)) {
        Write-Host "  [PASS] $log exists" -ForegroundColor Green
        $pass++
    } else {
        Write-Host "  [FAIL] $log missing" -ForegroundColor Red
        $fail++
    }
}

# TEST 5: Menu structure
Write-Host "`n[TEST 5] Menu structure" -ForegroundColor Cyan
$menuDir = "buttons\mainUI"
$folders = @("Settings", "SettingsCommand", "TextInput", "Tools")
foreach ($folder in $folders) {
    if (Test-Path (Join-Path $menuDir $folder)) {
        Write-Host "  [PASS] $folder exists" -ForegroundColor Green
        $pass++
    } else {
        Write-Host "  [FAIL] $folder missing" -ForegroundColor Red
        $fail++
    }
}

# SUMMARY
Write-Host "`n================================================================================" -ForegroundColor Green
Write-Host "  TEST SUMMARY" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "`nTotal Tests: $($pass + $fail)" -ForegroundColor Cyan
Write-Host "Passed:      $pass" -ForegroundColor Green
Write-Host "Failed:      $fail" -ForegroundColor Red

$rate = if ($pass + $fail -gt 0) { [int](($pass / ($pass + $fail)) * 100) } else { 0 }
Write-Host "Success Rate: $rate%" -ForegroundColor $(if ($rate -ge 90) { "Green" } else { "Yellow" })

if ($fail -eq 0) {
    Write-Host "`n[SUCCESS] ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[WARNING] Some tests failed" -ForegroundColor Yellow
    exit 1
}
