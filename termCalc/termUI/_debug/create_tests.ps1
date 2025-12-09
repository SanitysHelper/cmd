# Comprehensive stress test for termUI
# Tests: navigation, spam keys, boundary conditions, rapid input

$testDir = Split-Path -Parent $PSScriptRoot
$handlerPath = Join-Path $testDir "csharp\bin\InputHandler.exe"

if (-not (Test-Path $handlerPath)) {
    Write-Host "[ERROR] InputHandler not found at: $handlerPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== termUI Stress Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Basic navigation
Write-Host "[TEST 1] Basic Navigation" -ForegroundColor Yellow
$test1 = @"
Down
Down
Up
Enter
Escape
Q
"@
$test1File = Join-Path $PSScriptRoot "test1_basic.txt"
Set-Content -Path $test1File -Value $test1 -Encoding ASCII

# Test 2: Spam Down key
Write-Host "[TEST 2] Spam Down Key (50x)" -ForegroundColor Yellow
$test2 = "Down`n" * 50 + "Q`n"
$test2File = Join-Path $PSScriptRoot "test2_spam_down.txt"
Set-Content -Path $test2File -Value $test2 -Encoding ASCII

# Test 3: Spam Up key
Write-Host "[TEST 3] Spam Up Key (50x)" -ForegroundColor Yellow
$test3 = "Up`n" * 50 + "Q`n"
$test3File = Join-Path $PSScriptRoot "test3_spam_up.txt"
Set-Content -Path $test3File -Value $test3 -Encoding ASCII

# Test 4: Deep navigation
Write-Host "[TEST 4] Deep Navigation (submenu chain)" -ForegroundColor Yellow
$test4 = @"
Down
Enter
Down
Enter
Escape
Escape
Q
"@
$test4File = Join-Path $PSScriptRoot "test4_deep_nav.txt"
Set-Content -Path $test4File -Value $test4 -Encoding ASCII

# Test 5: Rapid alternating keys
Write-Host "[TEST 5] Rapid Alternating (Up/Down 30x)" -ForegroundColor Yellow
$test5 = ""
for ($i = 0; $i -lt 30; $i++) {
    $test5 += "Down`nUp`n"
}
$test5 += "Q`n"
$test5File = Join-Path $PSScriptRoot "test5_alternating.txt"
Set-Content -Path $test5File -Value $test5 -Encoding ASCII

# Test 6: Enter spam
Write-Host "[TEST 6] Spam Enter (20x)" -ForegroundColor Yellow
$test6 = "Enter`n" * 20 + "Q`n"
$test6File = Join-Path $PSScriptRoot "test6_spam_enter.txt"
Set-Content -Path $test6File -Value $test6 -Encoding ASCII

# Test 7: Escape spam
Write-Host "[TEST 7] Spam Escape (20x)" -ForegroundColor Yellow
$test7 = "Escape`n" * 20 + "Q`n"
$test7File = Join-Path $PSScriptRoot "test7_spam_escape.txt"
Set-Content -Path $test7File -Value $test7 -Encoding ASCII

# Test 8: Navigate all options
Write-Host "[TEST 8] Navigate All Options" -ForegroundColor Yellow
$test8 = @"
Down
Down
Down
Down
Down
Down
Down
Down
Down
Enter
Down
Down
Down
Escape
Down
Enter
Down
Down
Down
Escape
Q
"@
$test8File = Join-Path $PSScriptRoot "test8_all_options.txt"
Set-Content -Path $test8File -Value $test8 -Encoding ASCII

Write-Host ""
Write-Host "Test files created. Run tests manually:" -ForegroundColor Green
Write-Host "  Get-Content test1_basic.txt | .\csharp\bin\InputHandler.exe --replay test1_basic.txt" -ForegroundColor Gray
Write-Host ""
Write-Host "Or use run_all_tests.ps1 to automate" -ForegroundColor Green
