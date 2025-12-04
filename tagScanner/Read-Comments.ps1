# ==============================
#  Tag editor (EXE) directory selection
# ==============================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TagEditorDirStorePath = Join-Path $ScriptDir "tagEditorDirs.txt"
$MusicDirStorePath = Join-Path $ScriptDir "enteredDirectories.txt"

# Load stored tag editor dirs
$tagDirs = @()
if (Test-Path $TagEditorDirStorePath) {
    $tagDirs = Get-Content $TagEditorDirStorePath | ForEach-Object { $_.Trim('"').Trim() } | Where-Object { $_ -ne "" }
}

Write-Host "=== Select tag editor directory (folder that contains your EXE, e.g. exiftool.exe) ==="
if ($tagDirs.Count -gt 0) {
    for ($i = 0; $i -lt $tagDirs.Count; $i++) {
        Write-Host "[$i] = $($tagDirs[$i])"
    }
}
Write-Host "[$($tagDirs.Count)] = Enter new directory"

[int]$selectedIndex = -1
while ($true) {
    $input = Read-Host "Enter directory index for tag editor"
    if ([int]::TryParse($input, [ref]$selectedIndex) -and $selectedIndex -ge 0 -and $selectedIndex -le $tagDirs.Count) {
        break
    }
    Write-Host "Invalid selection. Try again." -ForegroundColor Yellow
}

$tagDir = $null
if ($selectedIndex -eq $tagDirs.Count) {
    while ($true) {
        $newDir = Read-Host "Enter full path to the tag editor directory"
        if (Test-Path $newDir) {
            $tagDir = (Resolve-Path $newDir).Path
            if (-not ($tagDirs -contains $tagDir)) {
                Add-Content -Path $TagEditorDirStorePath -Value "`"$tagDir`""
            }
            break
        }
        Write-Host "That path does not exist. Try again." -ForegroundColor Red
    }
} else {
    $tagDir = $tagDirs[$selectedIndex]
}

# Detect EXE in chosen folder
$exeFiles = Get-ChildItem -Path $tagDir -Filter *.exe -File -ErrorAction SilentlyContinue
if ($exeFiles.Count -eq 0) {
    Write-Host "No .exe found in '$tagDir'." -ForegroundColor Red
    exit
} elseif ($exeFiles.Count -eq 1) {
    $TagEditorExe = $exeFiles[0].FullName
} else {
    for ($i = 0; $i -lt $exeFiles.Count; $i++) {
        Write-Host "[$i] = $($exeFiles[$i].Name)"
    }
    while ($true) {
        $choice = Read-Host "Select which EXE to use"
        if ([int]::TryParse($choice, [ref]$ix) -and $ix -ge 0 -and $ix -lt $exeFiles.Count) {
            $TagEditorExe = $exeFiles[$ix].FullName
            break
        }
        Write-Host "Invalid selection." -ForegroundColor Yellow
    }
}
Write-Host "Using tag editor: $TagEditorExe"
Write-Host ""

# ==============================
#  Music directory selection
# ==============================

$storedDirs = @()
if (Test-Path $MusicDirStorePath) {
    $storedDirs = Get-Content $MusicDirStorePath | ForEach-Object { $_.Trim('"').Trim() } | Where-Object { $_ -ne "" }
}

Write-Host "=== Select music directory ==="
if ($storedDirs.Count -gt 0) {
    for ($i = 0; $i -lt $storedDirs.Count; $i++) {
        Write-Host "[$i] = $($storedDirs[$i])"
    }
}
Write-Host "[$($storedDirs.Count)] = Enter new directory"

[int]$dirIndex = -1
while ($true) {
    $input = Read-Host "Enter directory index for music"
    if ([int]::TryParse($input, [ref]$dirIndex) -and $dirIndex -ge 0 -and $dirIndex -le $storedDirs.Count) {
        break
    }
    Write-Host "Invalid selection. Try again." -ForegroundColor Yellow
}

$Root = $null
if ($dirIndex -eq $storedDirs.Count) {
    while ($true) {
        $newDir = Read-Host "Enter full path to your music directory"
        if (Test-Path $newDir) {
            $Root = (Resolve-Path $newDir).Path
            if (-not ($storedDirs -contains $Root)) {
                Add-Content -Path $MusicDirStorePath -Value "`"$Root`""
            }
            break
        }
        Write-Host "That path does not exist. Try again." -ForegroundColor Red
    }
} else {
    $Root = $storedDirs[$dirIndex]
}
Write-Host "Using directory: $Root"
Write-Host ""
