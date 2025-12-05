# Multi-Language Debugging Test Suite

$testDir = "c:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor"
cd $testDir

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "MULTI-LANGUAGE EXECUTION TESTS" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test C Code
Write-Host "[TEST 1] C Code - Simple Math Program" -ForegroundColor Yellow
@'
#include <stdio.h>

int main() {
    int a = 15, b = 25;
    printf("C Test: %d + %d = %d\n", a, b, a + b);
    return 0;
}
'@ | Set-Clipboard
$inputC = @'
C
R
'@
$inputC | cmd /c run.bat 2>&1 | Tee-Object -Variable outC
Write-Host "[TEST 1 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test C++ Code
Write-Host "[TEST 2] C++ Code - Vector and STL" -ForegroundColor Yellow
@'
#include <iostream>
#include <vector>

int main() {
    std::vector<int> nums = {10, 20, 30};
    int sum = 0;
    for (int n : nums) {
        sum += n;
    }
    std::cout << "C++ Test: Sum = " << sum << std::endl;
    return 0;
}
'@ | Set-Clipboard
$inputCpp = @'
C
R
'@
$inputCpp | cmd /c run.bat 2>&1 | Tee-Object -Variable outCpp
Write-Host "[TEST 2 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test Batch Code
Write-Host "[TEST 3] Batch Code - Windows CMD Commands" -ForegroundColor Yellow
@'
@echo off
setlocal enabledelayedexpansion
set /a result = 100 + 200
echo Batch Test: 100 + 200 = !result!
echo Running from: %CD%
'@ | Set-Clipboard
$inputBat = @'
C
R
'@
$inputBat | cmd /c run.bat 2>&1 | Tee-Object -Variable outBat
Write-Host "[TEST 3 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test PowerShell Code
Write-Host "[TEST 4] PowerShell Code - Built-in Functions" -ForegroundColor Yellow
@'
$numbers = @(5, 10, 15, 20)
$sum = ($numbers | Measure-Object -Sum).Sum
Write-Host "PowerShell Test: Sum = $sum"
Get-Date -Format "HH:mm:ss"
'@ | Set-Clipboard
$inputPs = @'
C
R
'@
$inputPs | cmd /c run.bat 2>&1 | Tee-Object -Variable outPs
Write-Host "[TEST 4 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test JavaScript Code
Write-Host "[TEST 5] JavaScript Code - Node.js" -ForegroundColor Yellow
@'
const values = [2, 4, 6, 8];
const total = values.reduce((a, b) => a + b, 0);
console.log("JavaScript Test: Sum = " + total);
'@ | Set-Clipboard
$inputJs = @'
C
R
'@
$inputJs | cmd /c run.bat 2>&1 | Tee-Object -Variable outJs
Write-Host "[TEST 5 COMPLETE]" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Test 1 (C):             $(if ($outC -match 'Test: \d+ \+ \d+ = \d+' -or $outC -match 'exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($outC -match 'Test:.*=' -or $outC -match 'exit code 0') { 'Green' } else { 'Red' })
Write-Host "Test 2 (C++):           $(if ($outCpp -match 'Sum = \d+' -or $outCpp -match 'exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($outCpp -match 'Sum|exit code 0') { 'Green' } else { 'Red' })
Write-Host "Test 3 (Batch):         $(if ($outBat -match '\d+ \+ \d+ = \d+' -or $outBat -match 'Batch Test') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($outBat -match 'Batch Test') { 'Green' } else { 'Red' })
Write-Host "Test 4 (PowerShell):    $(if ($outPs -match 'Sum = \d+') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($outPs -match 'Sum = \d+') { 'Green' } else { 'Red' })
Write-Host "Test 5 (JavaScript):    $(if ($outJs -match 'Sum = \d+' -or $outJs -match 'exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($outJs -match 'Sum|exit code 0') { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
