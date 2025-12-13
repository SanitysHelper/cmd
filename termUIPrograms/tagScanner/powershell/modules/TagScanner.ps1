######## Clean minimal TagScanner module ########
$ErrorActionPreference = 'Stop'

$script:metaflacCmd = $null
$script:taglibLoaded = $false

function Stop-LocalTermUI {
    try {
        $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $localExe = Join-Path $root "termUI.exe"
        $procs = Get-Process -Name termUI -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ($_.Path -ieq $localExe) }
        foreach ($p in $procs) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
        }
    } catch {}
}

function Kill-DependencyLockers {
    param([string]$TargetPath)
    try {
        $procs = Get-Process -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                if ($p.Modules) {
                    foreach ($m in $p.Modules) {
                        if ($m.FileName -and ($m.FileName -ieq $TargetPath)) {
                            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
                            break
                        }
                    }
                }
            } catch {
                # Access denied for some system processes; ignore
            }
        }
    } catch {}
}

function Sync-TempDependencies {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $bin = Join-Path $root "_bin"
    $depNames = @("TagLibSharp.dll","metaflac.exe","libflac.dll")
    foreach ($name in $depNames) {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("dep_" + $name)
        $target = Join-Path $bin $name
        if (Test-Path $temp) {
            try {
                Stop-LocalTermUI
                Kill-DependencyLockers -TargetPath $target
                Copy-Item -Path $temp -Destination $target -Force
                Remove-Item -Path $temp -Force -ErrorAction SilentlyContinue
            } catch {
                # If locked, skip; will retry next run
            }
        }
    }
}

function Test-Dependencies {
    Sync-TempDependencies
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $bin = Join-Path $root "_bin"
    $metaflac = Join-Path $bin "metaflac.exe"
    $taglib = Join-Path $bin "TagLibSharp.dll"
    $libflac = Join-Path $bin "libflac.dll"
    $ok = $true
    # Ensure local _bin is on PATH for this session so 'metaflac' resolves
    if ($env:PATH -notlike "*$bin*") { $env:PATH = "$bin;$env:PATH" }
    if (Test-Path $metaflac) { $script:metaflacCmd = $metaflac } else { try { $script:metaflacCmd = (Get-Command metaflac -ErrorAction Stop).Source } catch { $ok = $false } }
    # Ensure libflac.dll is present alongside metaflac for proper execution
    if (-not (Test-Path $libflac)) { $ok = $false }
    if (Test-Path $taglib) { try { if (-not $script:taglibLoaded) { Add-Type -Path $taglib; $script:taglibLoaded = $true } } catch { $ok = $false } } else { $ok = $false }
    if (-not $ok) {
        Write-Host "`n[SETUP REQUIRED] Missing dependencies (metaflac, libflac.dll, TagLibSharp.dll)" -ForegroundColor Yellow
        return $false
    }
    # Quick sanity: try invoking metaflac version to ensure no corruption
    try { & $script:metaflacCmd --version 2>$null | Out-Null } catch { Write-Host "[WARN] 'metaflac.exe' failed to run. Re-download via Dependencies → Auto Download." -ForegroundColor Yellow; return $false }
    return $true
}

function Select-Directory {
    $configDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "config"
    $configPath = Join-Path $configDir "scan_directory.txt"
    if (Test-Path $configPath) {
        $dir = (Get-Content -Path $configPath -Raw -ErrorAction SilentlyContinue).Trim()
        if ($dir -and (Test-Path $dir -PathType Container)) { Write-Host "`nUsing configured directory: $dir" -ForegroundColor Green; return $dir }
    }
    Write-Host "`n[INFO] No working directory configured." -ForegroundColor Yellow
    return $null
}

function Get-TestModeInput {
    param([string]$Prompt)
    $isTest = $env:TERMUI_TEST_MODE -eq "1"
    try {
        $handlerRef = $null
        if ($global:TERMUI_HANDLER) { $handlerRef = $global:TERMUI_HANDLER }
        elseif (Get-Variable -Name handler -Scope Global -ErrorAction SilentlyContinue) { $handlerRef = (Get-Variable -Name handler -Scope Global -ErrorAction SilentlyContinue).Value }
        if ($handlerRef -and $handlerRef.PSObject.Properties['IsTestMode'] -and $handlerRef.IsTestMode) {
            if (Get-Command -Name Get-TestInput -ErrorAction SilentlyContinue) {
                $val = Get-TestInput -EventBuffer $handlerRef.EventBuffer -Handler $handlerRef
                if ($null -eq $val) { $val = "" }
                Write-Host "$Prompt $val" -ForegroundColor Cyan
                return $val
            }
        }
    } catch {}
    if ($isTest) {
        Write-Host "$Prompt <auto-empty>" -ForegroundColor Cyan
        return ""
    }
    return (Read-Host $Prompt)
}

function Write-FlacTag { param([System.IO.FileInfo]$File,[string]$TagName,[string]$TagValue)
    if (-not $script:metaflacCmd) { return $false }
    & $script:metaflacCmd --remove-tag="$TagName" "$($File.FullName)" 2>&1 | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($TagValue)) { & $script:metaflacCmd --set-tag="${TagName}=${TagValue}" "$($File.FullName)" 2>&1 | Out-Null }
    return ($LASTEXITCODE -eq 0)
}

function Start-ReadModeDescriptionComment {
    if (-not (Test-Dependencies)) { return }
    $dir = Select-Directory
    if (-not $dir) { return }
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " READ MODE - Description/Comment" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\\.(mp3|flac)$' }
    foreach ($file in $files) {
        Write-Host "`nFile: $($file.FullName)" -ForegroundColor Yellow
        if ($file.Extension -eq '.flac' -and $script:metaflacCmd) { try { $desc = & $script:metaflacCmd --show-tag=DESCRIPTION $file.FullName 2>$null; $val = if ($desc) { ($desc -split '=', 2)[1] } else { "(empty)" }; Write-Host "  Description (FLAC): $val" } catch { Write-Host "  (error)" -ForegroundColor Red } }
        elseif ($file.Extension -eq '.mp3' -and $script:taglibLoaded) { try { $t = [TagLib.File]::Create($file.FullName); $val = $t.Tag.Comment; if (-not $val) { $val = "(empty)" }; Write-Host "  Comment (MP3): $val"; $t.Dispose() } catch { Write-Host "  (error)" -ForegroundColor Red } }
    }
}

function Start-WriteModeDescriptionComment {
    if (-not (Test-Dependencies)) { return }
    $dir = Select-Directory
    if (-not $dir) { return }
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " EDIT - Description/Comment" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    $value = Get-TestModeInput -Prompt "Enter value (blank to clear)"
    $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\\.(mp3|flac)$' }
    $ok = 0; $bad = 0
    foreach ($file in $files) {
        $success = $false
        if ($file.Extension -eq '.flac' -and $script:metaflacCmd) { $success = Write-FlacTag -File $file -TagName "DESCRIPTION" -TagValue $value }
        elseif ($file.Extension -eq '.mp3' -and $script:taglibLoaded) { try { $t = [TagLib.File]::Create($file.FullName); $t.Tag.Comment = $value; $t.Save(); $t.Dispose(); $success = $true } catch { $success = $false } }
        if ($success) { $ok++ } else { $bad++ }
    }
    Write-Host "Successful: $ok; Failed: $bad" -ForegroundColor Cyan
}

function Repair-Metadata {
    if (-not (Test-Dependencies)) { return }
    $dir = Select-Directory
    if (-not $dir) { return }
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " REPAIR METADATA" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\\.(mp3|flac)$' }
    $rep = 0; $err = 0
    foreach ($file in $files) {
        try {
            if ($file.Extension -eq '.flac' -and $script:metaflacCmd) { $null = & $script:metaflacCmd --test $file.FullName 2>&1; if ($LASTEXITCODE -ne 0) { $rep++ } }
            elseif ($file.Extension -eq '.mp3' -and $script:taglibLoaded) { $t = [TagLib.File]::Create($file.FullName); $t.Save(); $t.Dispose() }
        } catch { $err++ }
    }
    Write-Host "Repaired: $rep; Errors: $err" -ForegroundColor Cyan
}
