#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$termUIRoot = Join-Path $script:scriptDir "termUI"
$cmdRoot = Split-Path $script:scriptDir  # Parent is cmd directory

. (Join-Path $script:scriptDir "modules/TermUILibrary.ps1")

try {
    if (-not (Test-Path $termUIRoot)) { throw "termUI not found at $termUIRoot" }
    if (-not (Test-Path $cmdRoot)) { throw "cmd directory not found at $cmdRoot" }

    Write-Host "=== cmdBrowser ===" -ForegroundColor Green
    Write-Host "Scanning for programs..." -ForegroundColor DarkGray

    # Find all folders in cmd with run.bat
    $programs = @()
    $dirs = Get-ChildItem -Path $cmdRoot -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $runBat = Join-Path $dir.FullName "run.bat"
        if (Test-Path $runBat) {
            $programs += @{
                Name = $dir.Name
                Path = $dir.FullName
                RunBat = $runBat
            }
        }
    }

    if ($programs.Count -eq 0) {
        Write-Host "[WARN] No programs found (no run.bat files in cmd subdirectories)" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "[INFO] Found $($programs.Count) program(s)" -ForegroundColor Green

    # Create UI buttons for each program (no submenus)
    $mainUIRoot = Join-Path $termUIRoot "buttons\mainUI"
    if (Test-Path $mainUIRoot) { Remove-Item $mainUIRoot -Recurse -Force -ErrorAction SilentlyContinue }

    foreach ($prog in $programs) {
        New-TermUIButton -TermUIRoot $termUIRoot -Path "$($prog.Name).opt" -Description "Launch $($prog.Name)"
    }

    Write-Host "[INFO] UI buttons created. Launching browser..." -ForegroundColor Cyan

    # Launch UI and wait for selection
    $selection = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI"
    if (Test-TermUIQuit -SelectionResult $selection) {
        Write-Host "[INFO] Cancelled" -ForegroundColor Yellow
        exit 0
    }

    # Find selected program and launch it
    $selectedProgram = $programs | Where-Object { $_.Name -eq $selection.name } | Select-Object -First 1
    if (-not $selectedProgram) {
        Write-Host "[ERROR] Program not found: $($selection.name)" -ForegroundColor Red
        exit 1
    }

    Write-Host "`nLaunching: $($selectedProgram.Name)" -ForegroundColor Cyan
    Write-Host "Path: $($selectedProgram.Path)" -ForegroundColor DarkGray

    # Launch the selected program
    & cmd /c "cd `"$($selectedProgram.Path)`" && call run.bat"
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
