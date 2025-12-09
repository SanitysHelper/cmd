#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$termUIRoot = Join-Path $script:scriptDir "..\termUI"

. (Join-Path $script:scriptDir "modules/TermUIBridge.ps1")

function Calculate {
    param(
        [double]$A,
        [double]$B,
        [string]$Operation
    )
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
    Write-Host "=== termCalculator (termUI-driven) ===" -ForegroundColor Green
    Write-Host "Launching termUI to pick ValueA..." -ForegroundColor DarkGray
    $aChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI/SettingsCommand/ValueA" -CaptureTimeoutMs 0
    if ($null -eq $aChoice) { throw "No selection for ValueA" }

    Write-Host "Launching termUI to pick ValueB..." -ForegroundColor DarkGray
    $bChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI/SettingsCommand/ValueB" -CaptureTimeoutMs 0
    if ($null -eq $bChoice) { throw "No selection for ValueB" }

    Write-Host "Launching termUI to pick Operation..." -ForegroundColor DarkGray
    $opChoice = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI/SettingsCommand/Operation" -CaptureTimeoutMs 0
    if ($null -eq $opChoice) { throw "No selection for Operation" }

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
