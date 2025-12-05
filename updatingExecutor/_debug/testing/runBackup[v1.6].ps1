#!/usr/bin/env powershell
# runBackup[v1.6].ps1 - Advanced Testing Script for Updating Executor v1.6
# This script provides automated testing capabilities
# Generated: December 5, 2025

param(
    [switch]$Quick,
    [switch]$Full,
    [switch]$Verbose,
    [switch]$TestPython,
    [switch]$TestPowerShell,
    [switch]$TestBatch,
    [switch]$Interactive
)

$ErrorActionPreference = "Continue"
$VERSION = "1.6"
$SCRIPT_NAME = "runBackup[v$VERSION]"
$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommandPath
$EXEC_PATH = Join-Path $TEST_DIR "run.bat"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "$SCRIPT_NAME - Advanced Testing Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Version: $VERSION"
Write-Host "Test Directory: $TEST_DIR"
Write-Host "Executable: $EXEC_PATH"
Write-Host ""

# Test 1: Verify executable
if (-not (Test-Path $EXEC_PATH)) {
    Write-Host "[ERROR] Executable not found: $EXEC_PATH" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Executable found" -ForegroundColor Green

# Test 2: Wipe flag
Write-Host ""
Write-Host "[TEST 1/5] Testing /W wipe flag..." -ForegroundColor Yellow
Push-Location $TEST_DIR
& cmd /c "$EXEC_PATH /W >nul 2>&1"
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Wipe flag test passed" -ForegroundColor Green
} else {
    Write-Host "[✗] Wipe flag test failed (exit code $LASTEXITCODE)" -ForegroundColor Red
}
Pop-Location

# Test 3: Settings verification
Write-Host ""
Write-Host "[TEST 2/5] Checking settings.ini..." -ForegroundColor Yellow
$settings_path = Join-Path $TEST_DIR "settings.ini"
if (Test-Path $settings_path) {
    $settings = Get-Content $settings_path
    $count = ($settings | Where-Object { $_ -match "^[A-Z].*=" }).Count
    Write-Host "[✓] Settings file found ($count entries)" -ForegroundColor Green
} else {
    Write-Host "[✗] Settings file not found" -ForegroundColor Red
}

# Test 4: Documentation files
Write-Host ""
Write-Host "[TEST 3/5] Checking documentation..." -ForegroundColor Yellow
$docs = @("USER_GUIDE.md", "FINAL_SUMMARY.md", "TEST_REPORT.md")
$doc_count = 0
foreach ($doc in $docs) {
    $doc_path = Join-Path $TEST_DIR $doc
    if (Test-Path $doc_path) {
        Write-Host "[✓] $doc found" -ForegroundColor Green
        $doc_count++
    } else {
        Write-Host "[✗] $doc missing" -ForegroundColor Red
    }
}
Write-Host "[INFO] Documentation: $doc_count/$($docs.Count) files found"

# Test 5: Version backups
Write-Host ""
Write-Host "[TEST 4/5] Checking version backups..." -ForegroundColor Yellow
$backup_dir = Join-Path $TEST_DIR "backups"
if (Test-Path $backup_dir) {
    $backups = @(Get-ChildItem $backup_dir -Filter "run_v*.bat" -ErrorAction SilentlyContinue)
    Write-Host "[✓] Backups directory found ($($backups.Count) versions)" -ForegroundColor Green
    foreach ($backup in $backups) {
        Write-Host "  - $($backup.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "[✗] Backups directory not found" -ForegroundColor Red
}

# Test 6: Run space structure
Write-Host ""
Write-Host "[TEST 5/5] Checking run_space structure..." -ForegroundColor Yellow
$runspace = Join-Path $TEST_DIR "run_space"
if (Test-Path $runspace) {
    Write-Host "[✓] run_space directory found" -ForegroundColor Green
    
    $log_dir = Join-Path $runspace "log"
    if (Test-Path $log_dir) {
        Write-Host "[✓] log subdirectory found" -ForegroundColor Green
    } else {
        Write-Host "[✗] log subdirectory missing" -ForegroundColor Red
    }
    
    $lang_dir = Join-Path $runspace "languages"
    if (Test-Path $lang_dir) {
        Write-Host "[✓] languages subdirectory found" -ForegroundColor Green
    } else {
        Write-Host "[✗] languages subdirectory missing" -ForegroundColor Red
    }
} else {
    Write-Host "[✗] run_space directory missing" -ForegroundColor Red
}

# Optional: Run language tests
if ($TestPython -or $Full) {
    Write-Host ""
    Write-Host "[OPTIONAL] Testing Python code execution..." -ForegroundColor Cyan
    @"
print('Python test from runBackup script')
print('All systems operational!')
"@ | Set-Clipboard
    Write-Host "[INFO] Python code copied to clipboard - run: cd '$TEST_DIR' && .\run.bat" -ForegroundColor Yellow
}

if ($TestPowerShell -or $Full) {
    Write-Host ""
    Write-Host "[OPTIONAL] Testing PowerShell code execution..." -ForegroundColor Cyan
    @"
Write-Host 'PowerShell test from runBackup script'
Write-Host "Current directory: $(Get-Location)"
"@ | Set-Clipboard
    Write-Host "[INFO] PowerShell code copied to clipboard - run: cd '$TEST_DIR' && .\run.bat" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Tests Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Green
Write-Host "  .\runBackup[v$VERSION].ps1              # Run basic tests" -ForegroundColor Gray
Write-Host "  .\runBackup[v$VERSION].ps1 -Full        # Run full test suite" -ForegroundColor Gray
Write-Host "  .\runBackup[v$VERSION].ps1 -TestPython  # Test Python execution" -ForegroundColor Gray
Write-Host "  .\runBackup[v$VERSION].ps1 -TestPowerShell # Test PowerShell" -ForegroundColor Gray
Write-Host "  .\runBackup[v$VERSION].ps1 -Verbose     # Verbose output" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. Run interactive executor: cd '$TEST_DIR' && .\run.bat" -ForegroundColor Gray
Write-Host "  2. Copy code to clipboard: echo 'code' | Set-Clipboard" -ForegroundColor Gray
Write-Host "  3. Executor auto-selects defaults (5 sec boot, 3 sec main menu)" -ForegroundColor Gray
Write-Host "  4. Check logs: $([IO.Path]::Combine($TEST_DIR, 'run_space', 'log'))" -ForegroundColor Gray
Write-Host ""
