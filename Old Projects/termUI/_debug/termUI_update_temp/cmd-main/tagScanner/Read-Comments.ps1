# ===========================================
#  Unified Tag Tool (FLAC + MP3)
#  - Auto-detects metaflac.exe in tagEditorDirs.txt
#  - Auto-loads TagLib# (taglib-sharp.dll)
#  - Handles FLAC and MP3 separately but in one pass
#  - Debug mode controlled via settings.txt (debug=true/false)
# ===========================================

# --- Base paths ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MusicDirStorePath     = Join-Path $ScriptDir "enteredDirectories.txt"
$TagEditorDirStorePath = Join-Path $ScriptDir "tagEditorDirs.txt"
$SettingsPath          = Join-Path $ScriptDir "settings.txt"

# ===========================================
#  Settings / Debug mode
# ===========================================

# Create settings file if missing
if (-not (Test-Path $SettingsPath)) {
    "debug=false" | Out-File -FilePath $SettingsPath -Encoding utf8
}

# Read debug flag
$Debug = $false
try {
    $settingsLines = Get-Content -Path $SettingsPath -ErrorAction SilentlyContinue
    foreach ($line in $settingsLines) {
        $trim = $line.Trim()
        if ($trim -match '^debug\s*=\s*(true|false)$') {
            $value = $trim.Split('=')[1].Trim()
            $Debug = [System.Boolean]::Parse($value)
            break
        }
    }
} catch {
    $Debug = $false
}

if ($Debug) {
    Write-Host "Debug mode: ON (verbose per-file output)." -ForegroundColor Cyan
} else {
    Write-Host "Debug mode: OFF - only changes will be printed; empty tags are hidden." -ForegroundColor Cyan
}
Write-Host ""

# ===========================================
#  Helper: load stored directories
# ===========================================

function Load-Paths {
    param([string]$Path)
    if (Test-Path $Path) {
        $lines = @()
        foreach ($line in Get-Content -Path $Path -ErrorAction SilentlyContinue) {
            $trimmed = $line.Trim().Trim('"')
            if ($trimmed -ne "") { $lines += $trimmed }
        }
        return ,$lines
    } else {
        return @()
    }
}

$storedDirs = Load-Paths $MusicDirStorePath
$tagDirs    = Load-Paths $TagEditorDirStorePath

# =======================================================
#  Locate required tools automatically (metaflac.exe)
# =======================================================

$MetaFlacExe = $null

foreach ($dir in $tagDirs) {
    if (Test-Path $dir) {
        $flacExe = Get-ChildItem -Path $dir -Filter "metaflac.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($flacExe) {
            $MetaFlacExe = $flacExe.FullName
            break
        }
    }
}

if (-not $MetaFlacExe) {
    Write-Host "⚠️ metaflac.exe not found in any tagEditorDirs.txt paths." -ForegroundColor Red
    Write-Host "Add its directory to tagEditorDirs.txt (one path per line) and rerun." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
} else {
    Write-Host "✅ Found metaflac.exe: $MetaFlacExe"
    Write-Host ""
}

# =======================================================
#  TagLib# (for MP3s)
# =======================================================

$script:TagLibLoaded = $false

function Ensure-TagLibLoaded {
    if ($script:TagLibLoaded) { return }

    $dllPath = Join-Path $ScriptDir "taglib-sharp.dll"
    if (-not (Test-Path $dllPath)) {
        Write-Host "⚠️ taglib-sharp.dll not found in $ScriptDir" -ForegroundColor Red
        Write-Host "Download it (NuGet TagLibSharp) and place it in this folder." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit
    }

    Add-Type -Path $dllPath
    $script:TagLibLoaded = $true
    Write-Host "✅ Loaded TagLib# library."
    Write-Host ""
}

# =======================================================
#  MP3 Tag functions
# =======================================================

function Get-Mp3TagValue {
    param([string]$FilePath, [string]$TagName)
    Ensure-TagLibLoaded
    $audio = [TagLib.File]::Create($FilePath)
    $result = $null
    switch ($TagName.ToLower()) {
        'title'   { $result = $audio.Tag.Title }
        'artist'  { $result = ($audio.Tag.Performers -join '; ') }
        'album'   { $result = $audio.Tag.Album }
        'genre'   { $result = ($audio.Tag.Genres -join '; ') }
        'comment' { $result = $audio.Tag.Comment }
        'year'    { if ($audio.Tag.Year -gt 0) { $result = $audio.Tag.Year.ToString() } }
        'track'   { if ($audio.Tag.Track -gt 0) { $result = $audio.Tag.Track.ToString() } }
    }
    return $result
}

function Set-Mp3TagValue {
    param([string]$FilePath, [string]$TagName, [string]$Value)
    Ensure-TagLibLoaded
    $audio = [TagLib.File]::Create($FilePath)
    $val = if ([string]::IsNullOrEmpty($Value)) { "" } else { $Value }
    switch ($TagName.ToLower()) {
        'title'   { $audio.Tag.Title      = $val }
        'artist'  { $audio.Tag.Performers = @($val) }
        'album'   { $audio.Tag.Album      = $val }
        'genre'   { $audio.Tag.Genres     = @($val) }
        'comment' { $audio.Tag.Comment    = $val }
        'year'    {
            if ($val -match '^\d+$') { $audio.Tag.Year  = [uint32]$val }
            else                     { $audio.Tag.Year  = 0 }
        }
        'track'   {
            if ($val -match '^\d+$') { $audio.Tag.Track = [uint32]$val }
            else                     { $audio.Tag.Track = 0 }
        }
    }
    $audio.Save()
}

# =======================================================
#  FLAC Tag functions (metaflac)
# =======================================================

$FlacTagMap = @{
    'Artist'  = 'ARTIST'
    'Title'   = 'TITLE'
    'Album'   = 'ALBUM'
    'Comment' = 'COMMENT'
    'Genre'   = 'GENRE'
    'Track'   = 'TRACKNUMBER'
    'Year'    = 'DATE'
}

function Get-FlacTagValue {
    param([string]$FilePath, [string]$VorbisTag, [string]$ExePath)
    $lines = & $ExePath "--show-tag=$VorbisTag" $FilePath 2>$null
    if (-not $lines) { return $null }
    $values = @()
    foreach ($line in $lines) {
        $idx = $line.IndexOf('=')
        if ($idx -ge 0) { $values += $line.Substring($idx + 1) }
    }
    return ($values -join '; ')
}

function Set-FlacTagValue {
    param([string]$FilePath, [string]$VorbisTag, [string]$Value, [string]$ExePath)
    if ([string]::IsNullOrEmpty($Value)) {
        & $ExePath "--remove-tag=$VorbisTag" $FilePath | Out-Null
    } else {
        & $ExePath "--remove-tag=$VorbisTag" "--set-tag=$VorbisTag=$Value" $FilePath | Out-Null
    }
}

# =======================================================
#  Music Directory selection
# =======================================================

Write-Host "=== Select music directory (MP3 + FLAC) ==="
if ($storedDirs.Count -gt 0) {
    for ($i = 0; $i -lt $storedDirs.Count; $i++) {
        Write-Host "[$i] = $($storedDirs[$i])"
    }
}
Write-Host "[$($storedDirs.Count)] = Enter new directory"

$dirIndexRaw = Read-Host "Enter index"
[int]$dirIdx = $storedDirs.Count
[int]$tmp2 = 0
if ([int]::TryParse($dirIndexRaw, [ref]$tmp2)) {
    if ($tmp2 -ge 0 -and $tmp2 -lt $storedDirs.Count) { $dirIdx = $tmp2 }
}

if ($dirIdx -eq $storedDirs.Count) {
    do {
        $newDir = Read-Host "Enter full path to your music directory"
        if (Test-Path $newDir) {
            $Root = (Resolve-Path $newDir).Path
        } else {
            Write-Host "Invalid directory. Try again." -ForegroundColor Red
        }
    } until ($Root)
    if (-not ($storedDirs -contains $Root)) {
        Add-Content -Path $MusicDirStorePath -Value "`"$Root`""
        $storedDirs = Load-Paths $MusicDirStorePath
    }
} else {
    $Root = $storedDirs[$dirIdx]
}

Write-Host "Using directory: $Root"
Write-Host ""

# =======================================================
#  Tag + Action
# =======================================================

$tags = @('Artist','Title','Album','Comment','Genre','Track','Year')

Write-Host "=== Select tag to work with ==="
for ($i = 0; $i -lt $tags.Count; $i++) {
    Write-Host "[$i] = $($tags[$i])"
}

$tagIndex = $null
while ($true) {
    $tagIndexRaw = Read-Host "Enter tag index"
    if ([int]::TryParse($tagIndexRaw, [ref]$tagIndex) -and $tagIndex -ge 0 -and $tagIndex -lt $tags.Count) { break }
    Write-Host "Invalid selection. Try again." -ForegroundColor Yellow
}
$tagName = $tags[$tagIndex]
$vorbisTag = $FlacTagMap[$tagName]
Write-Host "Selected tag: $tagName"
Write-Host ""

Write-Host "[0] = read"
Write-Host "[1] = write"
do { $action = Read-Host "Enter action index" } until ($action -in @('0','1'))
Write-Host ""

# =======================================================
#  Collect MP3 + FLAC files
# =======================================================

Write-Host "Scanning '$Root' for .mp3 and .flac files..."
Write-Host ""

$files = Get-ChildItem -Path $Root -Recurse -File -Include *.mp3,*.flac
if ($files.Count -eq 0) {
    Write-Host "No .mp3 or .flac files found in $Root" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# If we have any MP3s, make sure TagLib is available (fail early)
if ($files | Where-Object { $_.Extension -ieq ".mp3" }) {
    try {
        Ensure-TagLibLoaded
    } catch {
        Read-Host "Press Enter to exit"
        exit
    }
}

# =======================================================
#  READ MODE
# =======================================================

if ($action -eq "0") {
    Write-Host "=== READ MODE: $tagName ==="
    if (-not $Debug) {
        Write-Host "Debug OFF: only non-empty tags will be printed."
        Write-Host ""
    }

    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $current = $null

        if ($ext -eq ".mp3") {
            $current = Get-Mp3TagValue -FilePath $file.FullName -TagName $tagName
        } elseif ($ext -eq ".flac") {
            $current = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        }

        if ($Debug) {
            Write-Host "----------------------------------------"
            Write-Host "File: $($file.Name)"
            if ([string]::IsNullOrWhiteSpace($current)) {
                Write-Host ("  {0}: <empty or not set>" -f $tagName)
            } else {
                Write-Host ("  {0}: {1}" -f $tagName, $current)
            }
        } else {
            # Only show non-empty tags when debug is OFF
            if (-not [string]::IsNullOrWhiteSpace($current)) {
                Write-Host ("{0} -> {1}" -f $file.Name, $current)
            }
        }
    }
}

# =======================================================
#  WRITE MODE
# =======================================================

if ($action -eq "1") {
    $newValue = Read-Host "Value to write (leave blank to delete)"
    $isDelete = [string]::IsNullOrEmpty($newValue)

    Write-Host ""
    if ($isDelete) {
        Write-Host "DELETE mode: tag '$tagName' will be removed where present."
    } else {
        Write-Host ("WRITE mode: setting tag '{0}' to '{1}'." -f $tagName, $newValue)
    }
    if (-not $Debug) {
        Write-Host "Debug OFF: only changed files will be printed."
    }
    Write-Host ""

    [int]$totalProcessed = 0
    [int]$totalChanged   = 0
    [int]$totalDeleted   = 0

    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $before = $null
        $after  = $null

        # Get current value
        if ($ext -eq ".mp3") {
            $before = Get-Mp3TagValue -FilePath $file.FullName -TagName $tagName
        }
        elseif ($ext -eq ".flac") {
            $before = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        }

        if ($Debug) {
            Write-Host "----------------------------------------"
            Write-Host "File: $($file.Name)"
            if ([string]::IsNullOrWhiteSpace($before)) {
                Write-Host "  Before: <empty or not set>"
            } else {
                Write-Host "  Before: $before"
            }

            if ($isDelete) {
                Write-Host "  Writing: (deleting tag)"
            } else {
                Write-Host "  Writing: '$newValue'"
            }
        }

        # Apply change
        if ($ext -eq ".mp3") {
            Set-Mp3TagValue -FilePath $file.FullName -TagName $tagName -Value $newValue
            $after = Get-Mp3TagValue -FilePath $file.FullName -TagName $tagName
        }
        elseif ($ext -eq ".flac") {
            Set-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -Value $newValue -ExePath $MetaFlacExe
            $after = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        }

        # Debug: detailed after + result
        if ($Debug) {
            if ($isDelete) {
                if ([string]::IsNullOrWhiteSpace($after)) {
                    Write-Host "  After: (deleted)"
                } else {
                    Write-Host "  After: $after"
                }
            } else {
                if ([string]::IsNullOrWhiteSpace($after)) {
                    Write-Host "  After: <empty or not set>"
                } else {
                    Write-Host "  After: $after"
                }
            }
        }

        $totalProcessed++

        if ($before -ne $after) {
            $totalChanged++
        }

        if ($isDelete -and -not [string]::IsNullOrWhiteSpace($before) -and [string]::IsNullOrWhiteSpace($after)) {
            $totalDeleted++
        }

        if ($Debug) {
            if ($before -ne $after) {
                Write-Host "  Result: success" -ForegroundColor Green
            } else {
                Write-Host "  Result: unmodified" -ForegroundColor Yellow
            }
        } else {
            # Non-debug: only print when a change actually happened
            if ($before -ne $after) {
                if ($isDelete) {
                    Write-Host ("Deleted {0} for: {1}" -f $tagName, $file.Name)
                } else {
                    Write-Host ("Updated {0} for: {1} -> '{2}'" -f $tagName, $file.Name, $after)
                }
            }
        }
    }

    Write-Host ""
    Write-Host "========== SUMMARY =========="
    Write-Host ("Processed [{0}] files." -f $totalProcessed)
    Write-Host ("Changed   [{0}] files."  -f $totalChanged)
    if ($isDelete) {
        Write-Host ("Deleted   [{0}] {1} tags." -f $totalDeleted, $tagName)
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Done."
Write-Host ""
[Console]::Write("Press C to close this window... ")
while ($true) {
    $key = [Console]::ReadKey($true)
    if ($key.KeyChar -eq 'c' -or $key.KeyChar -eq 'C') { break }
}
