$esc = [char]27
Write-Host ("{0}[2J{0}[H" -f $esc) -NoNewline
Write-Host "=== About termUI ===" -ForegroundColor Cyan
Write-Host "A lightweight terminal UI framework for PowerShell" -ForegroundColor Green
Write-Host ""
Write-Host "This is the standalone termUI framework." -ForegroundColor Yellow
Write-Host "Programs using termUI create their own buttons via InitializeButtons.ps1" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to return"
