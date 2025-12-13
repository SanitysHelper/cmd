#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$termUIRoot = Split-Path -Parent $scriptDir
$mainUI = Join-Path $termUIRoot "buttons\mainUI"

if (-not (Test-Path $mainUI)) {
    New-Item -ItemType Directory -Path $mainUI -Force | Out-Null
}

# Only seed defaults when no buttons exist to avoid overwriting program buttons
$existing = Get-ChildItem -Path $mainUI -Recurse -File -Include *.opt,*.ps1,*.input -ErrorAction SilentlyContinue
if ($existing.Count -gt 0) {
    return
}

$defaults = @(
    @{ Name = "About"; Opt = "About termUI framework"; Ps1 = @'
$isTestMode = $env:TERMUI_TEST_MODE -eq "1"
$esc = [char]27
Write-Host ("{0}[2J{0}[H" -f $esc) -NoNewline
Write-Host "=== About termUI ===" -ForegroundColor Cyan
Write-Host "A lightweight terminal UI framework for PowerShell" -ForegroundColor Green
Write-Host ""
Write-Host "This is the standalone termUI framework." -ForegroundColor Yellow
Write-Host "Programs using termUI create their own buttons via InitializeButtons.ps1" -ForegroundColor Yellow
Write-Host ""
if (-not $isTestMode) {
    Read-Host "Press Enter to return"
}
'@ },
    @{ Name = "Test"; Opt = "Simple test button"; Ps1 = @'
$isTestMode = $env:TERMUI_TEST_MODE -eq "1"
Write-Host "Test button executed successfully!" -ForegroundColor Green
if (-not $isTestMode) {
    Read-Host "Press Enter to continue"
}
'@ },
    @{ Name = "Show Version"; Opt = "Display current termUI version"; Ps1 = @'
$root = Split-Path -Parent $PSScriptRoot
$versionFile = Join-Path $root "VERSION.json"
if (Test-Path $versionFile) {
    try {
        $data = Get-Content -Path $versionFile -Raw | ConvertFrom-Json
        Write-Host "termUI Version: $($data.version)" -ForegroundColor Cyan
        Write-Host "Updated: $($data.lastUpdated)" -ForegroundColor DarkGray
    } catch {
        Write-Host "Unable to read version info." -ForegroundColor Red
    }
} else {
    Write-Host "VERSION.json not found." -ForegroundColor Red
}
'@ }
)

foreach ($def in $defaults) {
    $optPath = Join-Path $mainUI ("{0}.opt" -f $def.Name)
    $ps1Path = Join-Path $mainUI ("{0}.ps1" -f $def.Name)
    Set-Content -Path $optPath -Value $def.Opt -Encoding ASCII
    Set-Content -Path $ps1Path -Value $def.Ps1 -Encoding ASCII
}

Write-Host "Seeded default termUI buttons (About/Test/Show Version)" -ForegroundColor DarkGray
