function Invoke-GoogleDriveDownload {
    param(
        [string]$FileId,
        [string]$OutputPath
    )
    try {
        $headers = @{ 'User-Agent' = 'Mozilla/5.0'; 'Accept' = '*/*' }
        $url = "https://drive.google.com/uc?export=download&id=$FileId"
        $response = Invoke-WebRequest -Uri $url -Headers $headers -SessionVariable session -ErrorAction Stop -UseBasicParsing
        if ($response.Content -match 'confirm=([^&]+)') {
            $confirmToken = $matches[1]
            $url = "https://drive.google.com/uc?export=download&id=$FileId&confirm=$confirmToken"
            Invoke-WebRequest -Uri $url -Headers $headers -WebSession $session -OutFile $OutputPath -ErrorAction Stop -UseBasicParsing
        } else {
            Invoke-WebRequest -Uri $url -Headers $headers -WebSession $session -OutFile $OutputPath -ErrorAction Stop -UseBasicParsing
        }
        return $true
    } catch {
        Write-Host "  [ERROR] Google Drive download error: $_" -ForegroundColor Red
        return $false
    }
}

function Download-TagLibSharpFromNuGet {
    param(
        [string]$OutputPath
    )
    try {
        $nugetUrl = "https://www.nuget.org/api/v2/package/TagLibSharp"
        $tempBase = [System.IO.Path]::GetTempPath()
        $tempDir = Join-Path $tempBase ("taglibsharp_" + ([System.Guid]::NewGuid().ToString()))
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $nupkgPath = Join-Path $tempDir "TagLibSharp.nupkg"
        Invoke-WebRequest -Uri $nugetUrl -OutFile $nupkgPath -ErrorAction Stop -UseBasicParsing
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($nupkgPath, $tempDir)
        $candidatePaths = @(
            Join-Path $tempDir "lib\netstandard2.0\TagLibSharp.dll",
            Join-Path $tempDir "lib\net472\TagLibSharp.dll",
            Join-Path $tempDir "lib\net40\TagLibSharp.dll"
        )
        $dll = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $dll) { throw "TagLibSharp.dll not found in nupkg" }
        Copy-Item -Path $dll -Destination $OutputPath -Force
        return $true
    } catch {
        return $false
    } finally {
        if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Download-FileFromUrl {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$Retries = 2
    )
    for ($i = 0; $i -le $Retries; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -ErrorAction Stop
            return $true
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    return $false
}

function Try-ReleaseFileLock {
    param(
        [string]$TargetPath
    )
    $released = $false
    try {
        if (Test-Path $TargetPath) {
            $dir = Split-Path -Parent $TargetPath
            # Attempt to stop local termUI.exe if running from this program folder
            $termUIProcs = Get-Process -Name termUI -ErrorAction SilentlyContinue | Where-Object {
                $_.Path -and ($_.Path -like (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'termUI.exe'))
            }
            foreach ($p in $termUIProcs) {
                try {
                    Write-Host "  [INFO] Stopping termUI.exe (PID $($p.Id)) to release file locks..." -ForegroundColor DarkGray
                    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                    $released = $true
                } catch {}
            }
            # Small wait to allow OS to release locks
            Start-Sleep -Milliseconds 500
        }
    } catch {}
    return $released
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
    @{ name = "TagLibSharp.dll"; fileId = "1bvKyw6iryJg37VucN7R7vKeTiHuGZLQv"; path = "$binPath\TagLibSharp.dll"; altUrl = "https://www.nuget.org/api/v2/package/TagLibSharp" },
    # Prefer official source for FLAC binaries; keep Drive as fallback
    @{ name = "metaflac.exe"; fileId = "1_7B0jdEOKd6P3N5nsBdefY7PNTwrVBB_"; path = "$binPath\metaflac.exe"; altUrl = "https://github.com/xiph/flac/releases/download/1.4.3/flac-1.4.3-win.zip" },
    @{ name = "libflac.dll"; fileId = "1izhSM57DFeiDMCgoBOgdc_CHTwY8osdP"; path = "$binPath\libflac.dll"; altUrl = "https://github.com/xiph/flac/releases/download/1.4.3/flac-1.4.3-win.zip" }
)

Write-Host "Downloading dependencies from Google Drive..." -ForegroundColor White
Write-Host "Folder: $folderUrl`n" -ForegroundColor Gray

$downloadSuccessCount = 0
$downloadFailCount = 0

# Always delete files before download
foreach ($file in $filesToDownload) {
    if (Test-Path $file.path) {
        try {
            # Attempt to release locks before delete
            Try-ReleaseFileLock -TargetPath $file.path | Out-Null
            # Retry delete if locked
            $deleted = $false
            for ($i=0; $i -lt 3 -and -not $deleted; $i++) {
                try {
                    Remove-Item -Path $file.path -Force -ErrorAction Stop
                    $deleted = $true
                } catch {
                    Start-Sleep -Milliseconds 300
                }
            }
            if (-not $deleted) { throw "Unable to delete locked file: $($file.path)" }
            Write-Host "  [INFO] Deleted old: $($file.path)" -ForegroundColor DarkGray
        } catch {
            Write-Host "  [WARN] Could not delete: $($file.path) ($_ )" -ForegroundColor Yellow
            # Download to temp and replace on next launch
            $file['tempTarget'] = Join-Path ([System.IO.Path]::GetTempPath()) ("dep_" + [System.IO.Path]::GetFileName($file.path))
        }
    }
}

# Always download, never skip
foreach ($file in $filesToDownload) {
    Write-Host "Processing $($file.name)..." -ForegroundColor Yellow
    if ($file.name -eq "TagLibSharp.dll") {
        Write-Host "  Trying NuGet first: TagLibSharp" -ForegroundColor Gray
        if (Download-TagLibSharpFromNuGet -OutputPath $file.path) {
            Write-Host "  [OK] Downloaded via NuGet: $($file.name)" -ForegroundColor Green
            $downloadSuccessCount++
            continue
        } else {
            Write-Host "  [WARN] NuGet download failed; falling back to Google Drive" -ForegroundColor Yellow
        }
    }
    $targetPath = if ($file.ContainsKey('tempTarget') -and $file['tempTarget']) { $file['tempTarget'] } else { $file.path }
    if ($file.name -in @("metaflac.exe","libflac.dll")) {
        # Skip Google Drive for FLAC; use official zip
        if ($file.altUrl) {
            Write-Host "  Trying alternate source..." -ForegroundColor Gray
            # For FLAC zip, extract binaries
            if ($file.name -in @("metaflac.exe","libflac.dll")) {
                try {
                    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("flac_" + [System.Guid]::NewGuid())
                    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
                    $zipPath = Join-Path $tmp "flac.zip"
                    if (Download-FileFromUrl -Url $file.altUrl -OutputPath $zipPath) {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tmp)
                        $metaflacCandidate = Get-ChildItem -Path $tmp -Recurse -Filter "metaflac.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                        $libflacCandidate = Get-ChildItem -Path $tmp -Recurse -Filter "libFLAC.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($file.name -eq "metaflac.exe" -and $metaflacCandidate) {
                            Copy-Item $metaflacCandidate.FullName $targetPath -Force
                            Write-Host "  [OK] Downloaded via alternate: metaflac.exe" -ForegroundColor Green
                            $downloadSuccessCount++
                        } elseif ($file.name -eq "libflac.dll" -and $libflacCandidate) {
                            Copy-Item $libflacCandidate.FullName $targetPath -Force
                            Write-Host "  [OK] Downloaded via alternate: libflac.dll" -ForegroundColor Green
                            $downloadSuccessCount++
                        } else {
                            Write-Host "  [FAIL] Alternate source did not contain expected file" -ForegroundColor Red
                            $downloadFailCount++
                        }
                    } else {
                        Write-Host "  [FAIL] Alternate source download failed" -ForegroundColor Red
                        $downloadFailCount++
                    }
                } catch {
                    Write-Host "  [FAIL] Alternate extraction failed: $_" -ForegroundColor Red
                    $downloadFailCount++
                } finally {
                    if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
                }
            } else {
                if (Download-FileFromUrl -Url $file.altUrl -OutputPath $targetPath) {
                    Write-Host "  [OK] Downloaded via alternate: $($file.name)" -ForegroundColor Green
                    $downloadSuccessCount++
                } else {
                    Write-Host "  [FAIL] Alternate download failed" -ForegroundColor Red
                    # Fallback to Drive if configured
                    if ($file.fileId) {
                        Write-Host "  Trying Google Drive fallback..." -ForegroundColor Yellow
                        Write-Host "  Downloading from: https://drive.google.com/file/d/$($file.fileId)" -ForegroundColor Gray
                        if (Invoke-GoogleDriveDownload -FileId $file.fileId -OutputPath $targetPath) {
                            Write-Host "  [OK] Downloaded via Drive: $($file.name)" -ForegroundColor Green
                            $downloadSuccessCount++
                        } else {
                            $downloadFailCount++
                        }
                    } else {
                        $downloadFailCount++
                    }
                }
            }
        } else {
            Write-Host "  [FAIL] Missing alternate URL for $($file.name)" -ForegroundColor Red
            $downloadFailCount++
        }
    } else {
        # TagLibSharp via NuGet first, then Drive
        if ([string]::IsNullOrWhiteSpace($file.fileId)) {
            Write-Host "  [!] File ID not configured for $($file.name), skipping Drive." -ForegroundColor Yellow
            $downloadFailCount++
        } else {
            Write-Host "  Downloading from: https://drive.google.com/file/d/$($file.fileId)" -ForegroundColor Gray
            if (Invoke-GoogleDriveDownload -FileId $file.fileId -OutputPath $targetPath) {
                Write-Host "  [OK] Downloaded: $($file.name)" -ForegroundColor Green
                $downloadSuccessCount++
            } else {
                Write-Host "  [WARN] Google Drive failed: $($file.name)" -ForegroundColor Yellow
                $downloadFailCount++
            }
        }
    }
}

# If any downloads went to temp due to locks, inform user
if ($filesToDownload | Where-Object { $_.ContainsKey('tempTarget') -and $_['tempTarget'] }) {
    Write-Host "" 
    Write-Host "Some files were downloaded to a temporary location due to file locks:" -ForegroundColor Yellow
    foreach ($f in $filesToDownload) {
        if ($f.ContainsKey('tempTarget') -and $f['tempTarget']) { Write-Host "  - $($f.name): $($f['tempTarget'])" -ForegroundColor Gray }
    }
    Write-Host "Close termUI and rerun 'Auto Download' to finalize replacement, or manually copy the temp file over the locked target." -ForegroundColor Gray
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
