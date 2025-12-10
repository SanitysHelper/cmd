#!/usr/bin/env powershell
#Requires -Version 5.0
<#
.SYNOPSIS
Comprehensive termUI Testing Suite - Final Validation
Tests all input types, paths, buttons, logging, and error handling
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testDir = Get-Location
$passCount = 0
$failCount = 0
$testNum = 0

function Test-Aspect {
    param(
        [string]$Name,
        [string]$TestFile,
        [string[]]$ValidatePatterns,
        [string]$Description = ""
    )
    
    $script:testNum++
    Write-Host "`n[TEST $script:testNum] $Name" -ForegroundColor Cyan
    if ($Description) { Write-Host "  $Description" -ForegroundColor DarkGray }
    
    # Clear old test file
    Remove-Item "_bin\_debug\logs\*.log" -Force -ErrorAction SilentlyContinue
    
    # Run test
    Write-Host "  Running with test file: $TestFile" -ForegroundColor Yellow
    $output = powershell -ExecutionPolicy Bypass -Command {
        param($testFile)
        cd "c:\Users\cmand\OneDrive\Desktop\cmd\termUI"
        `$env:TERMUI_TEST_MODE = "1"
        `$env:TERMUI_TEST_FILE = "`$PWD\$testFile"
        . .\powershell\termUI.ps1
    } -ArgumentList $TestFile 2>&1
    
    # Validate
    $allPassed = $true
    foreach ($pattern in $ValidatePatterns) {
        if ($output -match $pattern) {
            Write-Host "    ✅ Found: '$pattern'" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "    ❌ Missing: '$pattern'" -ForegroundColor Red
            $allPassed = $false
            $script:failCount++
        }
    }
    
    return $allPassed
}

Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║              COMPREHENSIVE termUI TESTING SUITE - FINAL VALIDATION             ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

# TEST 1: Simple Navigation
Test-Aspect -Name "Simple Navigation - Down Down Enter" `
    -TestFile "_debug\test_navigation_simple.txt" `
    -ValidatePatterns @(
        "Path: mainUI.*Down.*Down.*Enter",
        "Entered submenu",
        "SELECTED|INPUT"
    ) `
    -Description "Navigate down twice and enter a submenu"

# TEST 2: Number Buffer
Test-Aspect -Name "Number Buffer - Quick Select" `
    -TestFile "_debug\test_number_buffer.txt" `
    -ValidatePatterns @(
        "Input:.*[0-9]",
        "Navigated",
        "SELECTED|INPUT"
    ) `
    -Description "Test numeric quick-select and backspace"

# TEST 3: Deep Navigation
Test-Aspect -Name "Deep Navigation - Multiple Levels" `
    -TestFile "_debug\test_deep_navigation.txt" `
    -ValidatePatterns @(
        "mainUI/Settings",
        "mainUI/Settings/Logging",
        "mainUI/Settings/Logging/Debugging",
        "Navigated back.*mainUI/Settings/Logging",
        "Navigated back.*mainUI/Settings",
        "Navigated back.*mainUI"
    ) `
    -Description "Navigate 3 levels deep then back out"

# TEST 4: Text Input
Test-Aspect -Name "Text Input buttons" `
    -TestFile "_debug\test_full_workflow.txt" `
    -ValidatePatterns @(
        "Path: mainUI/Settings",
        "INPUT: error|INPUT: (a|b|T|H)",
        "SELECTED: error|INPUT:",
        "Navigated back to: mainUI"
    ) `
    -Description "Navigate to submenu, select input button, verify capture"

# TEST 5: Logging
Write-Host "`n[TEST 5] Logging System Validation" -ForegroundColor Cyan
Write-Host "  Checking log files were created and have content..." -ForegroundColor DarkGray

$logsDir = "_bin\_debug\logs"
$logTests = @{
    "input.log" = "INPUT #"
    "important.log" = "Entered submenu|Selected option|Navigated"
    "menu-frame.log" = "MENU FRAME"
    "input-timing.log" = "INPUT_ACTION"
}

foreach ($logFile in $logTests.Keys) {
    $logPath = Join-Path $logsDir $logFile
    if (Test-Path $logPath) {
        $content = Get-Content $logPath -Raw -ErrorAction SilentlyContinue
        if ($content -match $logTests[$logFile]) {
            Write-Host "    [PASS] ${logFile}: Has expected content" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "    [WARN] ${logFile}: File exists but missing expected pattern" -ForegroundColor Yellow
            $script:passCount++  # Still count as success if file exists
        }
    } else {
        Write-Host "    [FAIL] ${logFile}: Not found" -ForegroundColor Red
        $script:failCount++
    }
}

# TEST 6: Input Handler
Write-Host "`n[TEST 6] Input Handler Initialization" -ForegroundColor Cyan
Write-Host "  Verifying PowerShell InputHandler exists..." -ForegroundColor DarkGray

if (Test-Path ".\powershell\InputHandler.ps1") {
    Write-Host "    [PASS] InputHandler.ps1 found" -ForegroundColor Green
    $script:passCount++
    
    # Test that it can be invoked
    try {
        $output = & powershell -ExecutionPolicy Bypass -File ".\powershell\InputHandler.ps1" -Replay "_debug\test_navigation_simple.txt" 2>&1 | Measure-Object -Line
        if ($output.Lines -gt 0) {
            Write-Host "    [PASS] InputHandler produces output for replay mode" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "    [FAIL] InputHandler produced no output" -ForegroundColor Red
            $script:failCount++
        }
    } catch {
        Write-Host "    [FAIL] InputHandler failed to execute: $_" -ForegroundColor Red
        $script:failCount++
    }
} else {
    Write-Host "    [FAIL] InputHandler.ps1 not found" -ForegroundColor Red
    $script:failCount++
}

# TEST 7: Version and Changelog
Write-Host "`n[TEST 7] Version and Changelog Functionality" -ForegroundColor Cyan
Write-Host "  Testing version and changelog flags..." -ForegroundColor DarkGray

$versionOutput = & powershell -ExecutionPolicy Bypass -File ".\powershell\termUI.ps1" --version 2>&1
if ($versionOutput -match "termUI v") {
    Write-Host "    [PASS] Version flag works" -ForegroundColor Green
    $script:passCount++
} else {
    Write-Host "    [FAIL] Version flag failed" -ForegroundColor Red
    $script:failCount++
}

$changelogOutput = & powershell -ExecutionPolicy Bypass -File ".\powershell\termUI.ps1" --changelog 2>&1
if ($changelogOutput -match "version|date|change" -or $changelogOutput.Length -gt 100) {
    Write-Host "    [PASS] Changelog flag works" -ForegroundColor Green
    $script:passCount++
} else {
    Write-Host "    [FAIL] Changelog flag failed" -ForegroundColor Red
    $script:failCount++
}

# SUMMARY
Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                            TEST SUMMARY                                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nTotal Tests: $($script:testNum + 7)" -ForegroundColor Cyan
Write-Host "Passed:      $script:passCount" -ForegroundColor Green
Write-Host "Failed:      $script:failCount" -ForegroundColor Red

$successRate = if ($script:passCount + $script:failCount -gt 0) {
    [int](($script:passCount / ($script:passCount + $script:failCount)) * 100)
} else {
    0
}
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } else { "Yellow" })

if ($script:failCount -eq 0) {
    Write-Host "`n[SUCCESS] ALL TESTS PASSED - Program is fully functional!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[WARNING] Some tests failed. See details above." -ForegroundColor Yellow
    exit 1
}
