#Requires -Version 5.0
<#
.SYNOPSIS
    Automated test runner for tagScanner using termUI test mode
.DESCRIPTION
    Launches termUI in test mode with predefined input sequences to verify functionality
.PARAMETER TestFile
    Path to the JSON test input file
.PARAMETER Verify
    If set, validates output against expected results
.EXAMPLE
    .\Run-Test.ps1 -TestFile _tests\test_read_artist.json
#>

param(
    [string]$TestFile = "_tests\test_read_artist.json",
    [switch]$Verify
)

$ErrorActionPreference = "Stop"

# Paths
$script:testRoot = Split-Path -Parent $PSCommandPath
$script:tagScannerRoot = Split-Path -Parent $script:testRoot
$script:termUIRoot = Join-Path (Split-Path -Parent $script:tagScannerRoot) "termUI"
$script:termUIExe = Join-Path $script:termUIRoot "termUI.exe"
$script:testInputFile = Join-Path $script:testRoot $TestFile

if (-not (Test-Path $script:testInputFile)) {
    Write-Host "[ERROR] Test file not found: $script:testInputFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $script:termUIExe)) {
    Write-Host "[ERROR] termUI.exe not found: $script:termUIExe" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " tagScanner Automated Test Runner" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test File: $TestFile" -ForegroundColor Gray
Write-Host ""

# Set environment variables for test mode
$env:TERMUI_TEST_MODE = "1"
$env:TERMUI_TEST_FILE = $script:testInputFile

# Set working directory to tagScanner so it uses tagScanner's termUI.ps1
Push-Location $script:tagScannerRoot

try {
    Write-Host "[INFO] Launching termUI in test mode..." -ForegroundColor Cyan
    Write-Host "[INFO] Test input: $script:testInputFile" -ForegroundColor Gray
    Write-Host ""
    
    # Launch tagScanner's termUI.ps1 directly
    $termUIPS1 = Join-Path $script:tagScannerRoot "powershell\termUI.ps1"
    
    $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $termUIPS1
    
    $exitCode = $LASTEXITCODE
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Test Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Exit Code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
    
    if ($Verify) {
        Write-Host ""
        Write-Host "[VERIFY] Checking output log..." -ForegroundColor Cyan
        $outputLog = Join-Path $script:tagScannerRoot "_bin\_debug\logs\output.log"
        if (Test-Path $outputLog) {
            $content = Get-Content $outputLog -Raw
            if ($content -match "ARTIST") {
                Write-Host "[PASS] Found FLAC tag output" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] No FLAC tag output found" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Log files available at:" -ForegroundColor Cyan
    Write-Host "  - $script:tagScannerRoot\_bin\_debug\logs\output.log" -ForegroundColor Gray
    Write-Host "  - $script:tagScannerRoot\_bin\_debug\logs\ui-transcript.log" -ForegroundColor Gray
    
    exit $exitCode
    
} catch {
    Write-Host "[ERROR] Test failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
    Remove-Item Env:\TERMUI_TEST_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:\TERMUI_TEST_FILE -ErrorAction SilentlyContinue
}
