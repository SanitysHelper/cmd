$ErrorActionPreference = "Stop"

function Read-Input {
    Write-Host "Enter desired proxy amount (e.g., 500):" -ForegroundColor Cyan
    $v = Read-Host
    if (-not ($v -match '^[0-9]+$')) { Write-Host "Invalid number." -ForegroundColor Red; return $null }
    return [int]$v
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ini = Join-Path $root "settings.ini"
$val = Read-Input
if ($null -eq $val) { return }

if (-not (Test-Path $ini)) { New-Item -ItemType File -Path $ini -Force | Out-Null }
# Update or append key
$content = if (Test-Path $ini) { Get-Content $ini } else { @() }
$found = $false
for ($i=0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^proxy_amount=') { $content[$i] = "proxy_amount=$val"; $found = $true }
}
if (-not $found) { $content += "proxy_amount=$val" }
$content | Set-Content -Path $ini -Encoding ASCII
Write-Host "Saved proxy_amount=$val" -ForegroundColor Green
