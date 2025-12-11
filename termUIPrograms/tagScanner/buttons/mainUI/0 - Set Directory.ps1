$script:configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"
if (-not (Test-Path $script:configDir)) { New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null }
$script:dirPath = Join-Path $script:configDir "scan_directory.txt"

# Load existing path if available
$script:selectedDir = ""
if (Test-Path $script:dirPath) {
    $script:selectedDir = Get-Content -Path $script:dirPath -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
}

# Show current directory or prompt for new one
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SET SCAN DIRECTORY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($script:selectedDir -and (Test-Path $script:selectedDir)) {
    Write-Host "Current directory: $script:selectedDir" -ForegroundColor Green
}

Write-Host "`nSelect new directory? (Y/N): " -ForegroundColor Gray -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    # Load WinForms assembly
    Add-Type -AssemblyName System.Windows.Forms
    
    # Create folder browser dialog
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the directory containing audio files (MP3, FLAC)"
    $dialog.ShowNewFolderButton = $true
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:selectedDir = $dialog.SelectedPath
        
        # Save to config file
        $script:selectedDir | Set-Content -Path $script:dirPath -Encoding UTF8 -Force
        Write-Host "Directory saved: $script:selectedDir" -ForegroundColor Green
    }
    else {
        Write-Host "No directory selected." -ForegroundColor Yellow
    }
}

Write-Host "Press any key to return to menu..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
