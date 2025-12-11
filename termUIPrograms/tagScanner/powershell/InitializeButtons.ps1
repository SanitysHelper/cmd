#Requires -Version 5.0
# TagScanner Button Initializer - Creates dynamic buttons on startup
Set-StrictMode -Version Latest

$script:tagScannerRoot = Split-Path -Parent $PSScriptRoot
$script:cmdRoot = Split-Path -Parent $script:tagScannerRoot
$script:termUIRoot = Join-Path $script:cmdRoot "termUI"
$script:buttonsRoot = Join-Path $script:tagScannerRoot "buttons\mainUI"
$script:dirsSubmenu = Join-Path $script:buttonsRoot "Directories"
$script:readSubmenu = Join-Path $script:buttonsRoot "Read Mode"
$script:writeSubmenu = Join-Path $script:buttonsRoot "Write Mode"

# Clear existing buttons and ensure directory exists
if (Test-Path $script:buttonsRoot) {
    Remove-Item -Path $script:buttonsRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $script:buttonsRoot -Force | Out-Null
New-Item -ItemType Directory -Path $script:dirsSubmenu -Force | Out-Null
New-Item -ItemType Directory -Path $script:readSubmenu -Force | Out-Null
New-Item -ItemType Directory -Path $script:writeSubmenu -Force | Out-Null
# Ensure no README files exist per user preference
Remove-Item -Path (Join-Path $script:readSubmenu "README.opt") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $script:readSubmenu "README.ps1") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $script:writeSubmenu "README.opt") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $script:writeSubmenu "README.ps1") -Force -ErrorAction SilentlyContinue

# Create main menu button files (.opt files contain descriptions)
# Do not create README files in submenus
# (Removed) No standalone Dependencies option; using submenu only.

# Create main UI level buttons
# (No default main UI buttons - kept clean)
# Create PowerShell scripts for each button
$addDirScript = Join-Path $script:dirsSubmenu "Add Directory.ps1"
# Add Directory option description (.opt)
"Create a new saved directory button" | Set-Content -Path (Join-Path $script:dirsSubmenu "Add Directory.opt") -Encoding UTF8
$readModeScript = $null
$writeModeScript = $null
$depsRoot = Join-Path $script:buttonsRoot "Dependencies"
New-Item -ItemType Directory -Path $depsRoot -Force | Out-Null

# Persisted directories list in config
$script:configDir = Join-Path $script:tagScannerRoot "config"
if (-not (Test-Path $script:configDir)) { New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null }
$script:dirsListPath = Join-Path $script:configDir "directories.json"
if (-not (Test-Path $script:dirsListPath)) { "[]" | Set-Content -Path $script:dirsListPath -Encoding UTF8 }

# Add Directory script (creates a new button inside Directories and sets it active)
@'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$configDir = Join-Path $root "config"
$dirsJson = Join-Path $configDir "directories.json"
$scanPath = Join-Path $configDir "scan_directory.txt"
$dirsFolder = Join-Path $root "buttons\mainUI\Directories"

if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
if (-not (Test-Path $dirsFolder)) { New-Item -ItemType Directory -Path $dirsFolder -Force | Out-Null }
if (-not (Test-Path $dirsJson)) { "[]" | Set-Content -Path $dirsJson -Encoding UTF8 }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " ADD DIRECTORY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
$newDir = Read-Host "Enter directory path"
if (-not $newDir -or -not (Test-Path $newDir -PathType Container)) {
    Write-Host "Invalid directory." -ForegroundColor Red
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return
}

# Update directories.json - ensure proper array handling
try {
    $content = Get-Content -Path $dirsJson -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content) -or $content -eq '[]') {
        $list = @()
    } else {
        $parsed = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -is [array]) {
            $list = $parsed
        } else {
            $list = @($parsed)
        }
    }
    if (-not ($list -contains $newDir)) { $list += $newDir }
    ($list | ConvertTo-Json) | Set-Content -Path $dirsJson -Encoding UTF8
} catch {}

# Create a button for this directory using safe path as filename
$safePath = ($newDir -replace '\\', '_' -replace ':', '')
$optPath = Join-Path $dirsFolder ("$safePath.opt")
$ps1Path = Join-Path $dirsFolder ("$safePath.ps1")
"$newDir" | Set-Content -Path $optPath -Encoding UTF8
$content = @(
    '$configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"',
    '$scanPath = Join-Path $configDir "scan_directory.txt"',
    ('"' + $newDir + '" | Set-Content -Path $scanPath -Encoding UTF8 -Force'),
    ('Write-Host "Working directory set: ' + $newDir + '" -ForegroundColor Green'),
    'Write-Host "Press any key to continue..." -ForegroundColor DarkGray',
    '$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")'
)
$content | Set-Content -Path $ps1Path -Encoding UTF8

# Also set as current working directory immediately
"$newDir" | Set-Content -Path $scanPath -Encoding UTF8 -Force
Write-Host "Working directory set: $newDir" -ForegroundColor Green
Write-Host "The new directory has been added." -ForegroundColor Cyan

# Refresh termUI menu to show new directory button
try {
    $termUIRoot = "c:/Users/cmand/OneDrive/Desktop/cmd/termUI"
    $refreshHelper = Join-Path $termUIRoot "powershell/modules/RefreshHelper.ps1"
    if (Test-Path $refreshHelper) {
        . $refreshHelper
        Invoke-TermUIMenuRefresh
        Write-Host "Menu updated with new directory." -ForegroundColor Green
    }
} catch {
    Write-Host "Note: Manual menu refresh may be needed." -ForegroundColor Gray
}

Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@ | Set-Content -Path $addDirScript -Encoding UTF8
# Build Read/Write tag option scripts
$tags = @(
    @{ name = "Artist"; id = "Artist" },
    @{ name = "Album"; id = "Album" },
    @{ name = "Title"; id = "Title" },
    @{ name = "Description"; id = "Description" },
    @{ name = "Comment"; id = "Comment" },
    @{ name = "Year"; id = "Year" }
)

function New-TagScript {
    param(
        [string]$folder,
        [string]$name,
        [string]$mode, # Read or Write
        [string]$id
    )
    $opt = Join-Path $folder ("$name.opt")
    $ps1 = Join-Path $folder ("$name.ps1")
    if ($mode -eq 'Read') {
        "Display $name tag for files" | Set-Content -Path $opt -Encoding UTF8
    } else {
        "Edit $name tag for files" | Set-Content -Path $opt -Encoding UTF8
    }
    $lines = @(
        '$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"',
        'if (Test-Path $modulePath) {',
        '  . $modulePath',
        ('  Start-' + $mode + 'ModeTag -Tag "' + $id + '"'),
        '} else {',
        '  Write-Host ("ERROR: TagScanner.ps1 module not found at: " + $modulePath) -ForegroundColor Red',
        '}'
    )
    $lines | Set-Content -Path $ps1 -Encoding UTF8
}

foreach ($t in $tags) {
    New-TagScript -folder $script:readSubmenu -name $t.name -mode 'Read' -id $t.id
    New-TagScript -folder $script:writeSubmenu -name $t.name -mode 'Write' -id $t.id
}

# Extras submenus
$extrasRead = Join-Path $script:readSubmenu "Extras"
$extrasWrite = Join-Path $script:writeSubmenu "Extras"
New-Item -ItemType Directory -Path $extrasRead -Force | Out-Null
New-Item -ItemType Directory -Path $extrasWrite -Force | Out-Null

$extraTags = @(
    @{ name = "Genre"; id = "Genre" },
    @{ name = "Track"; id = "Track" },
    @{ name = "Disc"; id = "Disc" },
    @{ name = "Composer"; id = "Composer" },
    @{ name = "Album Artist"; id = "AlbumArtist" },
    @{ name = "ISRC"; id = "ISRC" },
    @{ name = "Publisher"; id = "Publisher" },
    @{ name = "Conductor"; id = "Conductor" },
    @{ name = "Encoded By"; id = "EncodedBy" },
    @{ name = "Copyright"; id = "Copyright" }
)
foreach ($t in $extraTags) {
    New-TagScript -folder $extrasRead -name $t.name -mode 'Read' -id $t.id
    New-TagScript -folder $extrasWrite -name $t.name -mode 'Write' -id $t.id
}

# README scripts are not created

# Dependencies script
# Dependencies submenu options
# 1) Check Dependencies
"Check if TagLibSharp.dll and metaflac.exe are installed correctly" | Set-Content -Path (Join-Path $depsRoot "Check Dependencies.opt") -Encoding UTF8
@'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "powershell\modules\TagScanner.ps1"
if (Test-Path $modulePath) {
    . $modulePath
    Check-Dependencies
} else {
    Write-Host "ERROR: TagScanner.ps1 module not found at: $modulePath" -ForegroundColor Red
}
'@ | Set-Content -Path (Join-Path $depsRoot "Check Dependencies.ps1") -Encoding UTF8

# 2) Auto Download
"Automatically download and place required files from Google Drive" | Set-Content -Path (Join-Path $depsRoot "Auto Download.opt") -Encoding UTF8
$autoDownloadScript = @'
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
'@
$autoDownloadScript | Set-Content -Path (Join-Path $depsRoot "Auto Download.ps1") -Encoding UTF8

# 3) How to manually install
"Instructions to manually install required dependencies" | Set-Content -Path (Join-Path $depsRoot "How to manually install.opt") -Encoding UTF8
@'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$bin = Join-Path $root "_bin"
if (-not (Test-Path $bin)) { New-Item -ItemType Directory -Path $bin -Force | Out-Null }
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " MANUAL INSTALL" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("Place these files into: " + $bin) -ForegroundColor White
Write-Host "  - TagLibSharp.dll (for MP3 tags via TagLib#)" -ForegroundColor Green
Write-Host "  - metaflac.exe    (for FLAC tags)" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "Optionally add them to PATH if you prefer system-wide availability." -ForegroundColor Gray
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@ | Set-Content -Path (Join-Path $depsRoot "How to manually install.ps1") -Encoding UTF8

Write-Host "[tagScanner] Buttons initialized successfully:" -ForegroundColor Green
Write-Host "  - Directories (submenu)" -ForegroundColor Cyan
Write-Host "  - Read Mode (submenu)" -ForegroundColor Cyan
Write-Host "  - Write Mode (submenu)" -ForegroundColor Cyan
Write-Host "  - Dependencies (submenu)" -ForegroundColor Cyan

# Generate directory buttons from directories.json - handle both array and string
try {
    $content = Get-Content -Path $script:dirsListPath -Raw -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($content) -and $content -ne '[]') {
        $parsed = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
        $dirList = if ($parsed -is [array]) { $parsed } else { @($parsed) }
    } else {
        $dirList = @()
    }
    
    if ($dirList) {
        foreach ($d in $dirList) {
            if ([string]::IsNullOrWhiteSpace($d)) { continue }
            $safePath = ($d -replace '\\', '_' -replace ':', '')
            $optPath = Join-Path $script:dirsSubmenu ("$safePath.opt")
            $ps1Path = Join-Path $script:dirsSubmenu ("$safePath.ps1")
            "$d" | Set-Content -Path $optPath -Encoding UTF8
            $content = @(
                '$configDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "config"',
                '$scanPath = Join-Path $configDir "scan_directory.txt"',
                ('"' + $d + '" | Set-Content -Path $scanPath -Encoding UTF8 -Force'),
                ('Write-Host "Working directory set: ' + $d + '" -ForegroundColor Green'),
                'Write-Host "Press any key to continue..." -ForegroundColor DarkGray',
                '$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")'
            )
            $content | Set-Content -Path $ps1Path -Encoding UTF8
        }
    }
} catch {}


