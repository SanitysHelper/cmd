$isTestMode = $env:TERMUI_TEST_MODE -eq "1"
Write-Host "Test button executed successfully!" -ForegroundColor Green
if (-not $isTestMode) {
	Read-Host "Press Enter to continue"
}
