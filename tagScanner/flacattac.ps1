# ===========================================
#  FLAC Tag Tool (metaflac only)
#  - Remembers editor & music directories
#  - Works on .flac files using metaflac.exe
# ===========================================

# --- Where this script lives ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Files to store remembered directories ---
$MusicDirStorePath    = Join-Path $ScriptDir "enteredDirectories.txt"
$TagEditorDirStorePath = Join-Path $ScriptDir "tagEditorDirs.txt"

# --- Load stored directories safely (trim quotes) ---
function Load-Paths {
    param([string]$Path)
    if (Test-Path $Path) {
        return Get-Content $Path | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ -ne "" }
    } else {
        return @()
    }
}

$storedDirs = Load-Paths $MusicDirStorePath
$tagDirs    = Load-Paths $TagEditorDirStorePath

# ==============================
#  Tag editor (metaflac) selection
# ==============================

Write-Host "=== Select metaflac directory (folder with metaflac.exe) ==="
if ($tagDirs.Count -gt 0) {
    for ($i = 0; $i -lt $tagDirs.Count; $i++) {
        Write-Host "[$i] = $($tagDirs[$i])"
    }
}
Write-Host "[$($tagDirs.Count)] = Enter new directory"
$MetaFlacExe = $null

while (-not $MetaFlacExe) {
    $selectedIndexRaw = Read-Host "Enter index"
    $idx = $tagDirs.Count
    [void][int]::TryParse($selectedIndexRaw, [ref]$idx)
    if ($idx -lt 0 -or $idx -gt $tagDirs.Count) {
        $idx = $tagDirs.Count
    }

    if ($idx -eq $tagDirs.Count) {
        # New directory
        $tagDir = $null
        while (-not $tagDir) {
            $newDir = Read-Host "Enter full path to metaflac directory"
            if (Test-Path $newDir) {
                $tagDir = (Resolve-Path $newDir).Path
            } else {
                Write-Host "Invalid directory. Try again." -ForegroundColor Red
            }
        }
        if (-not ($tagDirs -contains $tagDir)) {
            Add-Content -Path $TagEditorDirStorePath -Value "`"$tagDir`""
            $tagDirs = Load-Paths $TagEditorDirStorePath
        }
    } else {
        $tagDir = $tagDirs[$idx]
        if (-not (Test-Path $tagDir)) {
            Write-Host "Stored directory '$tagDir' no longer exists. Choose another." -ForegroundColor Red
            continue
        }
    }

    # Look for metaflac.exe in this directory
    $exeFiles = Get-ChildItem -Path $tagDir -Filter *.exe -File -ErrorAction SilentlyContinue
    if ($exeFiles.Count -eq 0) {
        Write-Host "No .exe files found in '$tagDir'." -ForegroundColor Red
        continue
    }

    # If multiple EXEs, let user pick which one is metaflac.exe
    if ($exeFiles.Count -eq 1) {
        $MetaFlacExe = $exeFiles[0].FullName
    } else {
        Write-Host "Multiple .exe files found in '$tagDir':"
        for ($i = 0; $i -lt $exeFiles.Count; $i++) {
            Write-Host "[$i] = $($exeFiles[$i].Name)"
        }
        $pick = 0
        while ($true) {
            $pickRaw = Read-Host "Select EXE index (metaflac.exe)"
            if ([int]::TryParse($pickRaw, [ref]$pick) -and $pick -ge 0 -and $pick -lt $exeFiles.Count) {
                $MetaFlacExe = $exeFiles[$pick].FullName
                break
            }
            Write-Host "Invalid selection, try again." -ForegroundColor Yellow
        }
    }
}

Write-Host "Using tag editor: $MetaFlacExe"
Write-Host ""

# ==============================
#  Music directory selection
# ==============================

Write-Host "=== Select FLAC music directory ==="
if ($storedDirs.Count -gt 0) {
    for ($i = 0; $i -lt $storedDirs.Count; $i++) {
        Write-Host "[$i] = $($storedDirs[$i])"
    }
}
Write-Host "[$($storedDirs.Count)] = Enter new directory"

$dirIndexRaw = Read-Host "Enter index"
$dirIdx = $storedDirs.Count
[void][int]::TryParse($dirIndexRaw, [ref]$dirIdx)
if ($dirIdx -lt 0 -or $dirIdx -gt $storedDirs.Count) {
    $dirIdx = $storedDirs.Count
}

if ($dirIdx -eq $storedDirs.Count) {
    $Root = $null
    while (-not $Root) {
        $newDir = Read-Host "Enter full path to your FLAC music directory"
        if (Test-Path $newDir) {
            $Root = (Resolve-Path $newDir).Path
        } else {
            Write-Host "Invalid directory. Try again." -ForegroundColor Red
        }
    }
    if (-not ($storedDirs -contains $Root)) {
        Add-Content -Path $MusicDirStorePath -Value "`"$Root`""
        $storedDirs = Load-Paths $MusicDirStorePath
    }
} else {
    $Root = $storedDirs[$dirIdx]
}

Write-Host "Using directory: $Root"
Write-Host ""

# ==============================
#  Tag map + tag selection
# ==============================

# Map friendly names -> Vorbis comment tag names used by FLAC
$TagMap = [ordered]@{
    'Artist' = 'ARTIST'
    'Title'  = 'TITLE'
    'Album'  = 'ALBUM'
    'Comment' = 'COMMENT'
    'Genre'  = 'GENRE'
    'Track'  = 'TRACKNUMBER'
    'Year'   = 'DATE'
}

$tags = $TagMap.Keys

Write-Host "=== Select tag to work with ==="
for ($i = 0; $i -lt $tags.Count; $i++) {
    Write-Host "[$i] = $($tags[$i])"
}

$tagIndex = $null
while ($true) {
    $tagIndexRaw = Read-Host "Enter tag index"
    if ([int]::TryParse($tagIndexRaw, [ref]$tagIndex) -and $tagIndex -ge 0 -and $tagIndex -lt $tags.Count) {
        break
    }
    Write-Host "Invalid selection. Try again." -ForegroundColor Yellow
}

$tagName = $tags[$tagIndex]
$vorbisTag = $TagMap[$tagName]
Write-Host "Selected tag: $tagName (Vorbis: $vorbisTag)"
Write-Host ""

Write-Host "=== Choose action ==="
Write-Host "[0] = read"
Write-Host "[1] = write"

$action = $null
while ($true) {
    $actionRaw = Read-Host "Enter action index"
    if ($actionRaw -in @("0","1")) {
        $action = $actionRaw
        break
    }
    Write-Host "Invalid selection. Type 0 or 1." -ForegroundColor Yellow
}
Write-Host ""

# ==============================
#  Collect .flac files
# ==============================

Write-Host "Scanning '$Root' for .flac files..."
Write-Host ""

$files = Get-ChildItem -Path $Root -Recurse -File -Include *.flac
if ($files.Count -eq 0) {
    Write-Host "No .flac files found in $Root" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# ==============================
#  metaflac helpers
# ==============================

function Get-FlacTagValue {
    param(
        [string]$FilePath,
        [string]$VorbisTag,
        [string]$ExePath
    )

    # Show only this tag (returns lines like TAG=value)
    $lines = & $ExePath "--no-utf8-convert" ("--show-tag=$VorbisTag") $FilePath 2>$null
    if (-not $lines) { return $null }

    $values = @()
    foreach ($line in $lines) {
        $idx = $line.IndexOf('=')
        if ($idx -ge 0 -and $idx -lt ($line.Length - 1)) {
            $values += $line.Substring($idx + 1)
        }
    }

    if ($values.Count -eq 0) { return $null }
    return ($values -join '; ')
}

function Set-FlacTagValue {
    param(
        [string]$FilePath,
        [string]$VorbisTag,
        [string]$Value,
        [string]$ExePath
    )

    if ([string]::IsNullOrEmpty($Value)) {
        # Delete the tag
        & $ExePath ("--remove-tag=$VorbisTag") $FilePath | Out-Null
    } else {
        # Remove existing then set new tag value
        & $ExePath ("--remove-tag=$VorbisTag") ("--set-tag=$VorbisTag=$Value") $FilePath | Out-Null
    }
}

# ==============================
#  READ MODE
# ==============================

if ($action -eq "0") {
    Write-Host "=== READ MODE: $tagName ==="
    foreach ($file in $files) {
        $current = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        Write-Host "----------------------------------------"
        Write-Host "File: $($file.Name)"
        if ([string]::IsNullOrWhiteSpace($current)) {
            Write-Host "  $($tagName): <empty or not set>"
        } else {
            Write-Host "  $($tagName): $current"
        }
    }
}

# ==============================
#  WRITE MODE
# ==============================

if ($action -eq "1") {
    Write-Host "=== WRITE MODE: $tagName ==="
    Write-Host "This will apply to ALL .flac files under '$Root'."
    Write-Host "Leave the value blank to DELETE this tag from each file."
    Write-Host ""
    $newValue = Read-Host "Value to write"

    Write-Host ""
    Write-Host "Applying changes..."
    Write-Host ""

    foreach ($file in $files) {
        Write-Host "----------------------------------------"
        Write-Host "File: $($file.Name)"

        $before = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        if ([string]::IsNullOrWhiteSpace($before)) {
            Write-Host "  Before: <empty or not set>"
        } else {
            Write-Host "  Before: $before"
        }

        if ([string]::IsNullOrEmpty($newValue)) {
            Write-Host "  Writing: (deleting tag)"
        } else {
            Write-Host "  Writing: '$newValue'"
        }

        Set-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -Value $newValue -ExePath $MetaFlacExe

        $after = Get-FlacTagValue -FilePath $file.FullName -VorbisTag $vorbisTag -ExePath $MetaFlacExe
        if ([string]::IsNullOrWhiteSpace($after)) {
            Write-Host "  After: <empty or not set>"
        } else {
            Write-Host "  After: $after"
        }

        if ($before -ne $after) {
            Write-Host "  Result: success" -ForegroundColor Green
        } else {
            Write-Host "  Result: unmodified" -ForegroundColor Yellow
        }
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
