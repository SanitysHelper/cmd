# Full Debugging Test Suite for updatingExecutor

$testDir = "c:\Users\cmand\OneDrive\Desktop\cmd\updatingExecutor"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "FULL DEBUGGING RUN" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Boot Continue + Run
Write-Host "[TEST 1] Boot [C]ontinue + [R]un Python" -ForegroundColor Yellow
@'
print("TEST 1: Direct Run")
print(100 + 200)
'@ | Set-Clipboard
cd $testDir
$input1 = @'
C
R
'@
$input1 | cmd /c run.bat 2>&1 | Tee-Object -Variable out1
Write-Host "[TEST 1 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 2: Boot Continue + View
Write-Host "[TEST 2] Boot [C]ontinue + [V]iew only" -ForegroundColor Yellow
@'
# This is test code
x = 42
print(x)
'@ | Set-Clipboard
$input2 = @'
C
V
'@
$input2 | cmd /c run.bat 2>&1 | Tee-Object -Variable out2
Write-Host "[TEST 2 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 3: Boot Continue + Edit (choose Run as-is)
Write-Host "[TEST 3] Boot [C]ontinue + [E]dit + choose [R]un as-is" -ForegroundColor Yellow
@'
y = 50
print("Test 3 - Run as-is")
print(y * 2)
'@ | Set-Clipboard
$input3 = @'
C
E
R
'@
$input3 | cmd /c run.bat 2>&1 | Tee-Object -Variable out3
Write-Host "[TEST 3 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 4: Boot Continue + Detect (Python)
Write-Host "[TEST 4] Boot [C]ontinue + [D]etect language" -ForegroundColor Yellow
@'
import sys
print("Python detected")
'@ | Set-Clipboard
$input4 = @'
C
D
'@
$input4 | cmd /c run.bat 2>&1 | Tee-Object -Variable out4
Write-Host "[TEST 4 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 5: Boot Continue + Quit
Write-Host "[TEST 5] Boot [C]ontinue + [Q]uit" -ForegroundColor Yellow
@'
print("This won't run")
'@ | Set-Clipboard
$input5 = @'
C
Q
'@
$input5 | cmd /c run.bat 2>&1 | Tee-Object -Variable out5
Write-Host "[TEST 5 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 6: Boot Wipe (verify restoration)
Write-Host "[TEST 6] Boot [W]ipe run_space (verify helper restoration)" -ForegroundColor Yellow
$input6 = @'
W
'@
$input6 | cmd /c run.bat 2>&1 | Tee-Object -Variable out6
Write-Host ""
Write-Host "Files in run_space after wipe:"
Get-ChildItem "$testDir\run_space" | ForEach-Object { Write-Host "  - $($_.Name)" }
Write-Host "[TEST 6 COMPLETE]" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# Test 7: Boot after wipe + Run
Write-Host "[TEST 7] Boot [C]ontinue after wipe + [R]un (verify executor restored)" -ForegroundColor Yellow
@'
print("Running after wipe - executor should be restored")
'@ | Set-Clipboard
$input7 = @'
C
R
'@
$input7 | cmd /c run.bat 2>&1 | Tee-Object -Variable out7
Write-Host "[TEST 7 COMPLETE]" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Test 1 (Run):           $(if ($out1 -match 'Script finished with exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out1 -match 'exit code 0') { 'Green' } else { 'Red' })
Write-Host "Test 2 (View):          $(if ($out2 -match 'clipboard_code.py') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out2 -match 'clipboard_code') { 'Green' } else { 'Red' })
Write-Host "Test 3 (Edit-Run):      $(if ($out3 -match 'Script finished with exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out3 -match 'exit code 0') { 'Green' } else { 'Red' })
Write-Host "Test 4 (Detect):        $(if ($out4 -match 'Python') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out4 -match 'Python') { 'Green' } else { 'Red' })
Write-Host "Test 5 (Quit):          $(if ($out5 -match '\[EXIT\]' -or $out5 -match 'Done') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out5 -match 'Done|EXIT') { 'Green' } else { 'Red' })
Write-Host "Test 6 (Wipe):          $(if ((Get-ChildItem "$testDir\run_space" -Filter "*.bat" -ErrorAction SilentlyContinue).Count -gt 0) { 'PASS' } else { 'FAIL' })" -ForegroundColor Green
Write-Host "Test 7 (Post-wipe):     $(if ($out7 -match 'Script finished with exit code 0') { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($out7 -match 'exit code 0') { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
