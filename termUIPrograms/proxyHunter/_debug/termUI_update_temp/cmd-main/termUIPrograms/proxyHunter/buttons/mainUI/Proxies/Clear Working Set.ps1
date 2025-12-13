$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$bin = Join-Path $root "_bin"
$archive = Join-Path $root "_debug/archive"
if (-not (Test-Path $archive)) { New-Item -ItemType Directory -Path $archive -Force | Out-Null }

$confirm = Read-Host -Prompt "Type DELETE to remove working lists (raw/valid/to_scan)"
if ($confirm -ne "DELETE") { Write-Host "Canceled." -ForegroundColor Yellow; return }

$files = @("proxies_raw.txt","proxies_valid.txt","proxies_to_scan.txt")
foreach ($f in $files) {
    $p = Join-Path $bin $f
    if (Test-Path $p) {
        $ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
        $dest = Join-Path $archive ("${f}.${ts}")
        try { Move-Item -Path $p -Destination $dest -Force } catch { Remove-Item -Path $p -Force -ErrorAction SilentlyContinue }
        Write-Host "Cleared: $f" -ForegroundColor Green
    }
}
