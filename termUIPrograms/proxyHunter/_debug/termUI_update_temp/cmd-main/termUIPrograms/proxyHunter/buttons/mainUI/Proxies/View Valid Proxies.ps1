$ErrorActionPreference = "Stop"
# Program root is three levels up from buttons/mainUI/*
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$validPath = Join-Path $root "_bin/proxies_valid.txt"
$listDir = Join-Path $root "buttons/proxyList"
if (-not (Test-Path $validPath)) { Write-Host "No validated proxies yet. Run 'Find Proxies' first." -ForegroundColor Yellow; return }
if (-not (Test-Path $listDir)) { New-Item -ItemType Directory -Path $listDir -Force | Out-Null }

# Clear old proxy buttons, keep Back
Get-ChildItem -Path $listDir -File -Include *.ps1,*.opt | Where-Object { $_.BaseName -ne 'Back' } | ForEach-Object { Remove-Item $_.FullName -Force }

$proxies = Get-Content -Path $validPath | Where-Object { $_ -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}:\d+$' }
if ($proxies.Count -eq 0) { Write-Host "No validated proxies present." -ForegroundColor Yellow; return }

# Create a button per proxy
$idx = 1
foreach ($p in $proxies) {
	$safe = $p -replace '[^0-9A-Za-z\-\._]', '_'
	$name = "Proxy_$idx"
	$optPath = Join-Path $listDir "$name.opt"
	$ps1Path = Join-Path $listDir "$name.ps1"
	Set-Content -Path $optPath -Value $p -Encoding UTF8
	Set-Content -Path $ps1Path -Value (@(
		'$ErrorActionPreference = "Stop"',
		"Write-Host 'Proxy: $p' -ForegroundColor Green",
		"Write-Host 'Copied to clipboard.' -ForegroundColor DarkGray",
		"Set-Clipboard '$p'"
	) -join "`n") -Encoding UTF8
	$idx++
}

Write-Host "Loaded $($proxies.Count) proxy buttons." -ForegroundColor Cyan

# Request auto-navigation to proxyList submenu
if ($null -ne $global:Request-AutoNavigation) {
    & $global:Request-AutoNavigation -Path "proxyList"
}
