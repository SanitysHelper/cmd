#Requires -Version 5.0
# TagScanner Module - Audio file tag reading and writing for FLAC and MP3
Set-StrictMode -Version Latest

$script:historyFile = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "directory_history.txt"
$script:lastSelectedDir = $null

# FLAC tag names commonly used (metaflac uses Vorbis comment field names)
$script:flacCommonTags = @(
    "TITLE", "ARTIST", "ALBUM", "ALBUMARTIST", "DATE", "GENRE", "TRACKNUMBER", 
    "DISCNUMBER", "COMMENT", "COMPOSER", "PERFORMER", "COPYRIGHT", "LICENSE",
    "ORGANIZATION", "DESCRIPTION", "LOCATION", "CONTACT", "ISRC"
)

# MP3 ID3v2 frame names (id3v2 uses frame IDs)
$script:mp3FrameMap = @{
    "TIT2" = "Title"
    "TPE1" = "Artist"
    "TALB" = "Album"
    "TPE2" = "Album Artist"
    "TDRC" = "Year"
    "TCON" = "Genre"
    "TRCK" = "Track"
    "TPOS" = "Disc"
    "COMM" = "Comment"
    "TCOM" = "Composer"
    "TPE3" = "Conductor"
    "TPUB" = "Publisher"
    "TCOP" = "Copyright"
    "TENC" = "Encoded by"
    "TSRC" = "ISRC"
}

function Test-Dependencies {
    $missing = @()
    $metaflacPath = $null
    $taglibDllPath = $null

    # Preferred local bin locations inside tagScanner (program-local override)
    $localBin = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "_bin"
    $localMetaflac = Join-Path $localBin "metaflac.exe"
    $localTaglib = Join-Path $localBin "TagLibSharp.dll"

    # Check for metaflac
    if (Test-Path $localMetaflac) {
        $metaflacPath = $localMetaflac
    } else {
        try { $cmd = Get-Command metaflac -ErrorAction Stop; $metaflacPath = $cmd.Source } catch {}
    }

    # Check for TagLibSharp.dll
    if (Test-Path $localTaglib) {
        $taglibDllPath = $localTaglib
    }

    if (-not $metaflacPath) { $missing += "metaflac (FLAC metadata tool)" }
    if (-not $taglibDllPath) { $missing += "TagLibSharp.dll (MP3 tag library)" }

    if ($missing.Count -gt 0) {
        while ($true) {
            Write-Host "`n[SETUP REQUIRED] Missing tools detected:" -ForegroundColor Yellow
            foreach ($tool in $missing) { Write-Host "  - $tool" -ForegroundColor White }
            Write-Host "`nPlace the files as follows:" -ForegroundColor Cyan
            Write-Host "  - metaflac.exe -> termUIPrograms/tagScanner/_bin/metaflac.exe" -ForegroundColor Gray
            Write-Host "  - TagLibSharp.dll -> termUIPrograms/tagScanner/_bin/TagLibSharp.dll" -ForegroundColor Gray
            Write-Host "Or install them system-wide so they are in PATH." -ForegroundColor Gray
            Write-Host ""; Write-Host "Options:" -ForegroundColor Yellow
            Write-Host "  [R] Retry check" -ForegroundColor White
            Write-Host "  [Q] Cancel" -ForegroundColor White
            $ans = Read-Host "Enter choice (R/Q) after placing files"
            if ($ans -match '^[Qq]$') { return $false }

            # Re-check
            $missing = @()
            $metaflacPath = (Test-Path $localMetaflac) ? $localMetaflac : (try { (Get-Command metaflac -EA Stop).Source } catch { $null })
            $taglibDllPath = (Test-Path $localTaglib) ? $localTaglib : $null
            if (-not $metaflacPath) { $missing += "metaflac (FLAC metadata tool)" }
            if (-not $taglibDllPath) { $missing += "TagLibSharp.dll (MP3 tag library)" }
            if ($missing.Count -eq 0) { break }
        }
    }

    # Set invocations to prefer local bin if available
    if ($metaflacPath) { $script:metaflacCmd = $metaflacPath } else { $script:metaflacCmd = "metaflac" }
    if ($taglibDllPath) { 
        try {
            Add-Type -Path $taglibDllPath
            $script:taglibLoaded = $true
        } catch {
            Write-Host "[ERROR] Failed to load TagLibSharp.dll: $_" -ForegroundColor Red
            $script:taglibLoaded = $false
            return $false
        }
    } else {
        $script:taglibLoaded = $false
        return $false
    }
    return $true
}

function Get-DirectoryHistory {
    if (Test-Path $script:historyFile) {
        $dirs = Get-Content $script:historyFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        return @($dirs)
    }
    return @()
}

function Add-DirectoryToHistory {
    param([string]$Path)
    
    $history = Get-DirectoryHistory
    if ($Path -notin $history) {
        Add-Content -Path $script:historyFile -Value $Path -Encoding UTF8
    }
}

function Select-Directory {
    # Check if there's a saved directory in config first
    $configDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "config"
    $configPath = Join-Path $configDir "scan_directory.txt"
    
    if (Test-Path $configPath) {
        $savedDir = Get-Content -Path $configPath -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
        if ($savedDir -and (Test-Path $savedDir -PathType Container)) {
            Write-Host "`nUsing configured directory: $savedDir" -ForegroundColor Green
            Add-DirectoryToHistory -Path $savedDir
            return $savedDir
        }
    }
    
    $history = Get-DirectoryHistory
    
        # Prefer configured working directory set by Directories submenu
        $configDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "config"
        $configPath = Join-Path $configDir "scan_directory.txt"
        if (Test-Path $configPath) {
            $savedDir = Get-Content -Path $configPath -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
            if ($savedDir -and (Test-Path $savedDir -PathType Container)) {
                Write-Host "`nUsing configured directory: $savedDir" -ForegroundColor Green
                return $savedDir
            }
        }

        Write-Host "`n[INFO] No working directory configured." -ForegroundColor Yellow
        Write-Host "Use the 'Directories' submenu to add/select a directory." -ForegroundColor Gray
        Write-Host "Press any key to continue..." -ForegroundColor DarkGray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return $null
    
    if ($choice -eq "0") {
        $newPath = Read-Host "Enter directory path"
        if ([string]::IsNullOrWhiteSpace($newPath)) {
            Write-Host "[ERROR] No path entered" -ForegroundColor Red
            return $null
        }
        if (-not (Test-Path $newPath -PathType Container)) {
            Write-Host "[ERROR] Directory does not exist: $newPath" -ForegroundColor Red
            Write-Host "Press any key to continue..." -ForegroundColor Gray
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $null
        }
        Add-DirectoryToHistory -Path $newPath
        return $newPath
    }
    elseif ($choice -match '^\d+$') {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $history.Count) {
            $selectedPath = $history[$index]
            if (Test-Path $selectedPath -PathType Container) {
                return $selectedPath
            } else {
                Write-Host "[ERROR] Directory no longer exists: $selectedPath" -ForegroundColor Red
                Write-Host "Press any key to continue..." -ForegroundColor Gray
                $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return $null
            }
        }
    }
    
    Write-Host "[ERROR] Invalid selection" -ForegroundColor Red
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $null
        # Old selection flow removed; directory must be chosen via submenu buttons
}

function Get-AudioFiles {
    param([string]$Path)
    
    Write-Host "`nScanning directory recursively..." -ForegroundColor Yellow
    $flacFiles = @(Get-ChildItem -Path $Path -Filter "*.flac" -Recurse -File -ErrorAction SilentlyContinue)
    $mp3Files = @(Get-ChildItem -Path $Path -Filter "*.mp3" -Recurse -File -ErrorAction SilentlyContinue)
    
    $results = @{
        FLAC = $flacFiles
        MP3 = $mp3Files
        Total = $flacFiles.Count + $mp3Files.Count
    }
    
    Write-Host "Found $($flacFiles.Count) FLAC files and $($mp3Files.Count) MP3 files (Total: $($results.Total))" -ForegroundColor Green
    return $results
}

function Read-FlacTags {
    param([System.IO.FileInfo]$File)
    
    $tags = @{}
    try {
            $output = & $script:metaflacCmd --export-tags-to=- "$($File.FullName)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            foreach ($line in $output) {
                if ($line -match '^([^=]+)=(.*)$') {
                    $tagName = $matches[1]
                    $tagValue = $matches[2]
                    if (-not $tags.ContainsKey($tagName)) {
                        $tags[$tagName] = @()
                    }
                    $tags[$tagName] += $tagValue
                }
            }
        }
    } catch {
        Write-Host "[WARNING] Failed to read FLAC tags from $($File.Name): $_" -ForegroundColor Yellow
    }
    
    return $tags
}

function Read-Mp3Tags {
    param([System.IO.FileInfo]$File)
    $tags = @{}
    try {
        $tfile = [TagLib.File]::Create($File.FullName)
        $tag = $tfile.Tag
        # Common fields
        if ($tag.Title) { $tags['Title'] = $tag.Title }
        if ($tag.Artists) { $tags['Artist'] = ($tag.Artists -join ', ') }
        if ($tag.Album) { $tags['Album'] = $tag.Album }
        if ($tag.AlbumArtists) { $tags['Album Artist'] = ($tag.AlbumArtists -join ', ') }
        if ($tag.Year) { $tags['Year'] = [string]$tag.Year }
        if ($tag.Genres) { $tags['Genre'] = ($tag.Genres -join ', ') }
        if ($tag.Track) { $tags['Track'] = [string]$tag.Track }
        if ($tag.Disc) { $tags['Disc'] = [string]$tag.Disc }
        if ($tag.Comment) { $tags['Comment'] = $tag.Comment }
        # Also include all raw tag fields if available
        $tfile.Dispose()
    } catch {
        Write-Host "[WARNING] Failed to read MP3 tags from $($File.Name): $_" -ForegroundColor Yellow
    }
    return $tags
}

function Write-FlacTag {
    param(
        [System.IO.FileInfo]$File,
        [string]$TagName,
        [string]$TagValue
    )
    
    try {
        # Remove existing tag first
            $null = & $script:metaflacCmd --remove-tag="$TagName" "$($File.FullName)" 2>&1
        
        # Set new tag value
        if (-not [string]::IsNullOrWhiteSpace($TagValue)) {
                $null = & $script:metaflacCmd --set-tag="${TagName}=${TagValue}" "$($File.FullName)" 2>&1
        }
        
        return $LASTEXITCODE -eq 0
    } catch {
        Write-Host "[ERROR] Failed to write FLAC tag to $($File.Name): $_" -ForegroundColor Red
        return $false
    }
}

function Write-Mp3Tag {
    param(
        [System.IO.FileInfo]$File,
        [string]$Field,
        [string]$TagValue
    )
    try {
        $tfile = [TagLib.File]::Create($File.FullName)
        $tag = $tfile.Tag
        switch ($Field) {
            'Title' { $tag.Title = $TagValue }
            'Artist' { $tag.Performers = if ($TagValue) { @($TagValue) } else { @() } }
            'Album' { $tag.Album = $TagValue }
            'Album Artist' { $tag.AlbumArtists = if ($TagValue) { @($TagValue) } else { @() } }
            'Year' { $tag.Year = if ($TagValue) { [uint32]$TagValue } else { 0 } }
            'Genre' { $tag.Genres = if ($TagValue) { @($TagValue) } else { @() } }
            'Track' { $tag.Track = if ($TagValue) { [uint]$TagValue } else { 0 } }
            'Disc' { $tag.Disc = if ($TagValue) { [uint]$TagValue } else { 0 } }
            'Comment' { $tag.Comment = $TagValue }
            default { }
        }
        $tfile.Save(); $tfile.Dispose()
        return $true
    } catch {
        Write-Host "[ERROR] Failed to write MP3 tag to $($File.Name): $_" -ForegroundColor Red
        return $false
    }
}

function Start-ReadMode {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " READ MODE - Display Audio Tags" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (-not (Test-Dependencies)) { return }
    
    $directory = Select-Directory
    if (-not $directory) { return }
    
    $files = Get-AudioFiles -Path $directory
    
    if ($files.Total -eq 0) {
        Write-Host "`n[INFO] No audio files found in directory" -ForegroundColor Yellow
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Display FLAC files
    if ($files.FLAC.Count -gt 0) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host " FLAC FILES ($($files.FLAC.Count))" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Cyan
        
        foreach ($file in $files.FLAC) {
            Write-Host "`nFile: $($file.FullName)" -ForegroundColor Yellow
            $tags = Read-FlacTags -File $file
            
            if ($tags.Count -eq 0) {
                Write-Host "  [No tags found]" -ForegroundColor DarkGray
            } else {
                foreach ($tagName in ($tags.Keys | Sort-Object)) {
                    $values = $tags[$tagName] -join ", "
                    Write-Host "  $tagName = $values" -ForegroundColor White
                }
            }
        }
    }
    
    # Display MP3 files
    if ($files.MP3.Count -gt 0) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host " MP3 FILES ($($files.MP3.Count))" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Cyan
        
        foreach ($file in $files.MP3) {
            Write-Host "`nFile: $($file.FullName)" -ForegroundColor Yellow
            $tags = Read-Mp3Tags -File $file
            
            if ($tags.Count -eq 0) {
                Write-Host "  [No tags found]" -ForegroundColor DarkGray
            } else {
                foreach ($frameId in ($tags.Keys | Sort-Object)) {
                    $tagInfo = $tags[$frameId]
                    Write-Host "  $frameId ($($tagInfo.Description)) = $($tagInfo.Value)" -ForegroundColor White
                }
            }
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-WriteMode {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " WRITE MODE - Batch Edit Audio Tags" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (-not (Test-Dependencies)) { return }
    
    $directory = Select-Directory
    if (-not $directory) { return }
    
    $files = Get-AudioFiles -Path $directory
    
    if ($files.Total -eq 0) {
        Write-Host "`n[INFO] No audio files found in directory" -ForegroundColor Yellow
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Ask user to select file type
    Write-Host "`nSelect file type to edit:" -ForegroundColor Yellow
    Write-Host "  [1] FLAC files ($($files.FLAC.Count) files)" -ForegroundColor White
    Write-Host "  [2] MP3 files ($($files.MP3.Count) files)" -ForegroundColor White
    Write-Host "  [0] Cancel" -ForegroundColor DarkGray
    
    $fileTypeChoice = Read-Host "`nChoice"
    
    if ($fileTypeChoice -eq "0") { return }
    
    $targetFiles = @()
    $fileType = ""
    
    if ($fileTypeChoice -eq "1") {
        if ($files.FLAC.Count -eq 0) {
            Write-Host "[ERROR] No FLAC files found" -ForegroundColor Red
            Write-Host "Press any key to continue..." -ForegroundColor Gray
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        $targetFiles = $files.FLAC
        $fileType = "FLAC"
    }
    elseif ($fileTypeChoice -eq "2") {
        if ($files.MP3.Count -eq 0) {
            Write-Host "[ERROR] No MP3 files found" -ForegroundColor Red
            Write-Host "Press any key to continue..." -ForegroundColor Gray
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        $targetFiles = $files.MP3
        $fileType = "MP3"
    }
    else {
        Write-Host "[ERROR] Invalid selection" -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Select tag to edit
    Write-Host "`nSelect tag to edit:" -ForegroundColor Yellow
    
    if ($fileType -eq "FLAC") {
        for ($i = 0; $i -lt $script:flacCommonTags.Count; $i++) {
            Write-Host "  [$($i + 1)] $($script:flacCommonTags[$i])" -ForegroundColor White
        }
        Write-Host "  [0] Enter custom tag name" -ForegroundColor Green
    }
    else {
        $frameIds = $script:mp3FrameMap.Keys | Sort-Object
        for ($i = 0; $i -lt $frameIds.Count; $i++) {
            $frameId = $frameIds[$i]
            Write-Host "  [$($i + 1)] $frameId - $($script:mp3FrameMap[$frameId])" -ForegroundColor White
        }
    }
    
    $tagChoice = Read-Host "`nChoice"
    
    $selectedTag = $null
    
    if ($fileType -eq "FLAC") {
        if ($tagChoice -eq "0") {
            $selectedTag = Read-Host "Enter custom tag name (e.g., ARTIST, TITLE, etc.)"
            if ([string]::IsNullOrWhiteSpace($selectedTag)) {
                Write-Host "[ERROR] No tag name entered" -ForegroundColor Red
                Write-Host "Press any key to continue..." -ForegroundColor Gray
                $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            $selectedTag = $selectedTag.ToUpper()
        }
        elseif ($tagChoice -match '^\d+$') {
            $index = [int]$tagChoice - 1
            if ($index -ge 0 -and $index -lt $script:flacCommonTags.Count) {
                $selectedTag = $script:flacCommonTags[$index]
            }
        }
    }
    else {
        if ($tagChoice -match '^\d+$') {
            $index = [int]$tagChoice - 1
            $frameIds = $script:mp3FrameMap.Keys | Sort-Object
            if ($index -ge 0 -and $index -lt $frameIds.Count) {
                $selectedTag = $frameIds[$index]
            }
        }
    }
    
    if (-not $selectedTag) {
        Write-Host "[ERROR] Invalid tag selection" -ForegroundColor Red
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Get tag value
    Write-Host "`nEnter value for tag '$selectedTag':" -ForegroundColor Yellow
    Write-Host "(Leave empty to remove/clear the tag)" -ForegroundColor DarkGray
    $tagValue = Read-Host "Value"
    
    # Confirm operation
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " CONFIRMATION" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "File type: $fileType" -ForegroundColor White
    Write-Host "Target files: $($targetFiles.Count)" -ForegroundColor White
    Write-Host "Tag: $selectedTag" -ForegroundColor White
    Write-Host "Value: $tagValue" -ForegroundColor White
    Write-Host ""
    $confirm = Read-Host "Apply to all files? (y/n)"
    
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "[CANCELLED] No changes made" -ForegroundColor Yellow
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Apply changes
    Write-Host "`nApplying changes..." -ForegroundColor Yellow
    $successCount = 0
    $failCount = 0
    
    foreach ($file in $targetFiles) {
        Write-Host "Processing: $($file.Name)..." -ForegroundColor Gray
        
        $success = $false
        if ($fileType -eq "FLAC") {
            $success = Write-FlacTag -File $file -TagName $selectedTag -TagValue $tagValue
        }
        else {
            $success = Write-Mp3Tag -File $file -FrameId $selectedTag -TagValue $tagValue
        }
        
        if ($success) {
            $successCount++
        } else {
            $failCount++
        }
    }
    
    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " OPERATION COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Export functions
Export-ModuleMember -Function Start-ReadMode, Start-WriteMode
