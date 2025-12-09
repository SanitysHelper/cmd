# Interactive Mode Testing
# Tests arrow keys, backspace, quit, numeric input, etc.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiBuilderDir = Split-Path -Parent (Split-Path -Parent $scriptDir)

Write-Host "=== INTERACTIVE MODE TEST SUITE ===" -ForegroundColor Green
Write-Host "Testing edge cases and user interactions`n" -ForegroundColor Cyan

# Test 1: Down arrow and Enter
Write-Host "[TEST 1] Down arrow and Enter to select second item" -ForegroundColor Yellow
$script:test1_passed = $false
# This will need manual interaction or we need to add debug mode

# Test 2: Numeric input fallback
Write-Host "[TEST 2] Numeric input in interactive mode (when piped)" -ForegroundColor Yellow
$input = "2`n1"
$result = @($input -split "`n") | & "$uiBuilderDir\run.bat"
if ($LASTEXITCODE -eq 1) {
    Write-Host "PASS - Numeric input works with piped fallback`n" -ForegroundColor Green
} else {
    Write-Host "FAIL - Exit code: $LASTEXITCODE`n" -ForegroundColor Red
}

# Test 3: Back navigation (0)
Write-Host "[TEST 3] Back navigation with 0" -ForegroundColor Yellow
$input = "2`n0`n1"
$result = @($input -split "`n") | & "$uiBuilderDir\run.bat"
if ($LASTEXITCODE -eq 99) {
    Write-Host "PASS - Back navigation works`n" -ForegroundColor Green
} else {
    Write-Host "FAIL - Exit code: $LASTEXITCODE`n" -ForegroundColor Red
}

# Test 4: Quit with q
Write-Host "[TEST 4] Quit with 'q'" -ForegroundColor Yellow
$input = "1`nq"
$result = @($input -split "`n") | & "$uiBuilderDir\run.bat"
if ($LASTEXITCODE -eq 99) {
    Write-Host "PASS - Quit works`n" -ForegroundColor Green
} else {
    Write-Host "FAIL - Exit code: $LASTEXITCODE`n" -ForegroundColor Red
}

# Test 5: Invalid numeric input
Write-Host "[TEST 5] Invalid numeric input (should show error)" -ForegroundColor Yellow
$input = "99`n1"
$result = @($input -split "`n") | & "$uiBuilderDir\run.bat" 2>&1
if ($result -match "Invalid" -or $LASTEXITCODE -eq 1) {
    Write-Host "PASS - Invalid input handled`n" -ForegroundColor Green
} else {
    Write-Host "CHECK - Exit code: $LASTEXITCODE`n" -ForegroundColor Yellow
}

# Test 6: Deep submenu navigation
Write-Host "[TEST 6] Deep submenu navigation (mainUI > Tools > Advanced)" -ForegroundColor Yellow
$input = "2`n3"
$result = @($input -split "`n") | & "$uiBuilderDir\run.bat"
if ($LASTEXITCODE -eq 2) {  # Second selection in submenu
    Write-Host "PASS - Deep navigation works`n" -ForegroundColor Green
} else {
    Write-Host "EXIT CODE: $LASTEXITCODE`n" -ForegroundColor Cyan
}

Write-Host "=== TEST SUITE COMPLETE ===" -ForegroundColor Green
