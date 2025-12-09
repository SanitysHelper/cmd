# Test script: Inject synthetic key events into termUI
# Usage: .\test_ui.ps1

$testEventsFile = Join-Path $PSScriptRoot "test_events.txt"
$handlerPath = Join-Path $PSScriptRoot "csharp\bin\InputHandler.exe"

# Create test input sequence (Down, Down, Enter, Escape)
$events = @"
Down
Down
Enter
Escape
"@

Set-Content -Path $testEventsFile -Value $events -Encoding ASCII

# Launch UI with handler fed from test file
Write-Host "[TEST] Starting termUI with injected key sequence..." -ForegroundColor Cyan
& $handlerPath --replay $testEventsFile | powershell -NoProfile -ExecutionPolicy Bypass -Command {
    # Read events from pipeline and simulate UI reading them
    while ($input = $input -split "`n") {
        Write-Host "[TEST EVENT] $input" -ForegroundColor Yellow
    }
}

Write-Host "[TEST] Complete" -ForegroundColor Green
