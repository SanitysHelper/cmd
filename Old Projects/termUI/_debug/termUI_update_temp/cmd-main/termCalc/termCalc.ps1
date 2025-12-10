#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$termUIRoot = Join-Path $script:scriptDir "termUI"

. (Join-Path $script:scriptDir "modules/TermUILibrary.ps1")

function Calculate {
    param([double]$A, [double]$B, [string]$Operation)
    switch ($Operation.ToLower()) {
        "add" { return $A + $B }
        "subtract" { return $A - $B }
        "multiply" { return $A * $B }
        "divide" {
            if ($B -eq 0) { throw "Divide by zero" }
            return $A / $B
        }
        default { throw "Unknown operation '$Operation'" }
    }
}

try {
    if (-not (Test-Path $termUIRoot)) { throw "termUI not found at $termUIRoot" }

    Write-Host "=== termCalc (Calculator) ===" -ForegroundColor Green
    Write-Host "Building calculator buttons..." -ForegroundColor DarkGray

    # Build calculator buttons using the library
    $valueAButtons = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20)
    $valueBButtons = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20)
    $operations = @("add", "subtract", "multiply", "divide")

    foreach ($v in $valueAButtons) {
        New-TermUIButton -TermUIRoot $termUIRoot -Path "Calculator/ValueA/$v.opt" -Description "Set A to $v"
    }
    foreach ($v in $valueBButtons) {
        New-TermUIButton -TermUIRoot $termUIRoot -Path "Calculator/ValueB/$v.opt" -Description "Set B to $v"
    }
    foreach ($op in $operations) {
        New-TermUIButton -TermUIRoot $termUIRoot -Path "Calculator/Operation/$op.opt" -Description "Operation: $op"
    }
    New-TermUIButton -TermUIRoot $termUIRoot -Path "Calculator/Compute/calculate.opt" -Description "Calculate result"

    Write-Host "[INFO] Calculator buttons built." -ForegroundColor Green

    # Prompt for selections using the UI
    Write-Host "`nLaunching calculator UI..." -ForegroundColor Cyan
    $aChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "Calculator/ValueA"
    if (Test-TermUIQuit -SelectionResult $aChoice) {
        Write-Host "[INFO] Cancelled" -ForegroundColor Yellow
        return
    }

    $bChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "Calculator/ValueB"
    if (Test-TermUIQuit -SelectionResult $bChoice) {
        Write-Host "[INFO] Cancelled" -ForegroundColor Yellow
        return
    }

    $opChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "Calculator/Operation"
    if (Test-TermUIQuit -SelectionResult $opChoice) {
        Write-Host "[INFO] Cancelled" -ForegroundColor Yellow
        return
    }

    $a = [double]::Parse($aChoice.name)
    $b = [double]::Parse($bChoice.name)
    $op = $opChoice.name

    $result = Calculate -A $a -B $b -Operation $op

    Write-Host "" -ForegroundColor Gray
    Write-Host "A = $a" -ForegroundColor White
    Write-Host "B = $b" -ForegroundColor White
    Write-Host "Operation = $op" -ForegroundColor White
    Write-Host "" -ForegroundColor Gray
    Write-Host "Result: $a $op $b = $result" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
