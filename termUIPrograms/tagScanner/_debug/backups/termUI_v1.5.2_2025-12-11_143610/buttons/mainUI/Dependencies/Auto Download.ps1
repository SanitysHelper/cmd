function Invoke-GoogleDriveDownload {
    param(
        [string]$FileId,
        [string]$OutputPath
    )
    try {
        $url = "https://drive.google.com/uc?export=download&id=$FileId"
        $response = Invoke-WebRequest -Uri $url -SessionVariable session -ErrorAction Stop
        
        if ($response.Content -match 'confirm=([^&]+)') {
            $confirmToken = $matches[1]
            $url = "https://drive.google.com/uc?export=download&id=$FileId&confirm=$confirmToken"
            Invoke-WebRequest -Uri $url -WebSession $session -OutFile $OutputPath -ErrorAction Stop
        } else {
            Invoke-WebRequest -Uri $url -WebSession $session -OutFile $OutputPath -ErrorAction Stop
        }
        return $true
    } catch {
        return $false
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " AUTO DOWNLOAD" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$binPath = Join-Path $root "_bin"
if (-not (Test-Path $binPath)) { New-Item -ItemType Directory -Path $binPath -Force | Out-Null }

$folderId = "1QGwweRSs_FZUaIEzL0o2YMlG4xEcblfk"
$folderUrl = "https://drive.google.com/drive/folders/$folderId"

$filesToDownload = @(
    @{ name = "TagLibSharp.dll"; fileId = "1bvKyw6iryJg37VucN7R7vKeTiHuGZLQv"; path = "$binPath\TagLibSharp.dll" },
    @{ name = "metaflac.exe"; fileId = "1C3U2Dr-XvQJrd5xk_ipnhLlzPqhUeCjG"; path = "$binPath\metaflac.exe" }
)

Write-Host "Downloading dependencies from Google Drive..." -ForegroundColor White
Write-Host "Folder: $folderUrl`n" -ForegroundColor Gray

$downloadSuccessCount = 0
$downloadFailCount = 0

foreach ($file in $filesToDownload) {
    Write-Host "Processing $($file.name)..." -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($file.fileId)) {
        Write-Host "  [!] File ID not configured. To set up auto-download:" -ForegroundColor Cyan
        Write-Host "    1. Open the Google Drive folder" -ForegroundColor Gray
        Write-Host "    2. Right-click file and select Get link" -ForegroundColor Gray
        Write-Host "    3. Extract the file ID from the URL (between /d/ and /)" -ForegroundColor Gray
        Write-Host "    4. Contact the admin to configure the file IDs" -ForegroundColor Gray
        $downloadFailCount++
        continue
    }
    
    if (Test-Path $file.path) {
        Write-Host "  [OK] Already exists: $($file.path)" -ForegroundColor Green
        $downloadSuccessCount++
    } else {
        Write-Host "  Downloading from: https://drive.google.com/file/d/$($file.fileId)" -ForegroundColor Gray
        if (Invoke-GoogleDriveDownload -FileId $file.fileId -OutputPath $file.path) {
            Write-Host "  [OK] Downloaded: $($file.name)" -ForegroundColor Green
            $downloadSuccessCount++
        } else {
            Write-Host "  [FAIL] Failed to download: $($file.name)" -ForegroundColor Red
            $downloadFailCount++
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Downloaded/Found: $downloadSuccessCount" -ForegroundColor Green
Write-Host "  Failed/Unconfigured: $downloadFailCount" -ForegroundColor Yellow
Write-Host ""

if ($downloadSuccessCount -eq $filesToDownload.Count) {
    Write-Host "[OK] All dependencies downloaded successfully!" -ForegroundColor Green
} elseif ($downloadSuccessCount -gt 0) {
    Write-Host "[WARN] Some files could not be downloaded. Please download manually from:" -ForegroundColor Yellow
    Write-Host "  $folderUrl" -ForegroundColor White
    Write-Host "  And place them in: $binPath" -ForegroundColor White
} else {
    Write-Host "[INFO] Manual download required. Visit:" -ForegroundColor Cyan
    Write-Host "  $folderUrl" -ForegroundColor White
    Write-Host "  Download both files and place in: $binPath" -ForegroundColor White
}

Write-Host ""
Write-Host "Run 'Check Dependencies' after downloading to verify installation." -ForegroundColor Gray
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
