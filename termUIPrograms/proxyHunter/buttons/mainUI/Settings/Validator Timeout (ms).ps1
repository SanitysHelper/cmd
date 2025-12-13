$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$settings = Join-Path $root "settings.ini"
$val = Read-Host -Prompt "Enter validator timeout (ms)"
if (-not ($val -match '^[0-9]+$')) { Write-Host "Invalid number." -ForegroundColor Red; return }
$n = [int]$val; if ($n -lt 100) { $n = 100 } elseif ($n -gt 10000) { $n = 10000 }
$ini = if (Test-Path $settings) { Get-Content $settings -Raw } else { "" }
if ($ini -match "validator_timeout_ms=") { $ini = ($ini -replace "validator_timeout_ms=\d+", "validator_timeout_ms=$n") } else { $ini += "`nvalidator_timeout_ms=$n`n" }
Set-Content -Path $settings -Value $ini -Encoding UTF8
Write-Host "validator_timeout_ms set to $n" -ForegroundColor Green
