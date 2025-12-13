$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$settings = Join-Path $root "settings.ini"
$val = Read-Host -Prompt "Enter max threads (1-64)"
if (-not ($val -match '^[0-9]+$')) { Write-Host "Invalid number." -ForegroundColor Red; return }
$n = [int]$val; if ($n -lt 1) { $n = 1 } elseif ($n -gt 64) { $n = 64 }
$ini = if (Test-Path $settings) { Get-Content $settings -Raw } else { "" }
if ($ini -match "thread_amount=") { $ini = ($ini -replace "thread_amount=\d+", "thread_amount=$n") } else { $ini += "`nthread_amount=$n`n" }
Set-Content -Path $settings -Value $ini -Encoding UTF8
Write-Host "thread_amount set to $n" -ForegroundColor Green
