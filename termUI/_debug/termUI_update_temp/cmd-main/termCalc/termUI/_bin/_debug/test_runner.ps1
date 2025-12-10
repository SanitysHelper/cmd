$tests = @(
    @{Name="Down Navigation"; File="test_01_down_navigation.txt"}
    @{Name="Up Navigation"; File="test_02_up_navigation.txt"}
    @{Name="Enter Submenu"; File="test_03_enter_submenu.txt"}
    @{Name="Escape from Submenu"; File="test_04_escape_from_submenu.txt"}
    @{Name="Escape at Root"; File="test_05_escape_at_root.txt"}
)
$passed = 0; $failed = 0
foreach ($test in $tests) {
    Write-Host "`n=== $($test.Name) ===" -ForegroundColor Cyan
    $env:TERMUI_TEST_MODE = "1"
    $env:TERMUI_TEST_FILE = "$PSScriptRoot\$($test.File)"
    if (-not (Test-Path $env:TERMUI_TEST_FILE)) { Write-Host "[SKIP]" -ForegroundColor Yellow; continue }
    Remove-Item "$PSScriptRoot\logs\important.log" -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\logs\error.log" -ErrorAction SilentlyContinue
    Set-Location "$PSScriptRoot\.."
    & powershell -NoProfile -ExecutionPolicy Bypass -File "powershell\termUI.ps1" 2>&1 | Out-Null
    $important = Get-Content "$PSScriptRoot\logs\important.log" -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "Started input" }
    $errors = Get-Content "$PSScriptRoot\logs\error.log" -ErrorAction SilentlyContinue
    $important | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    if ($errors) { Write-Host "[FAILED]" -ForegroundColor Red; $failed++ } else { Write-Host "[PASSED]" -ForegroundColor Green; $passed++ }
}
Write-Host "`nPassed: $passed, Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
