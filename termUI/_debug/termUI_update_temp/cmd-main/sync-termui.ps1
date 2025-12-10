#Requires -Version 5.0
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $scriptDir "termUI"
$dest = Join-Path $scriptDir "termCalc/termUI"

if (-not (Test-Path $source)) { 
    Write-Host "[ERROR] Source termUI not found: $source" -ForegroundColor Red
    exit 1 
}

Write-Host "[INFO] Syncing termUI from cmd to termCalc..." -ForegroundColor Cyan

try {
    # Exclude buttons and logs from sync (keep per-program customizations)
    Remove-Item -Path $dest -Recurse -Force -ErrorAction SilentlyContinue
    
    Copy-Item -Path $source -Destination $dest -Recurse -Force -Exclude @("buttons", "_debug")
    
    # Ensure each has its own buttons/logs
    $destButtons = Join-Path $dest "buttons\mainUI"
    if (-not (Test-Path $destButtons)) { New-Item -ItemType Directory -Path $destButtons -Force | Out-Null }
    
    $destLogs = Join-Path $dest "_debug\logs"
    if (-not (Test-Path $destLogs)) { New-Item -ItemType Directory -Path $destLogs -Force | Out-Null }

    Write-Host "[OK] Sync complete" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
