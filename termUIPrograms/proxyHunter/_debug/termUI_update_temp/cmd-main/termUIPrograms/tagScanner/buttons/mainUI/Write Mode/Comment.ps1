$ErrorActionPreference = "Stop"

# Load TagScanner module
$scriptRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))))
$modulePath = Join-Path $scriptRoot "powershell/modules/TagScanner.ps1"
if (-not (Test-Path $modulePath)) { Write-Host "TagScanner module missing: $modulePath" -ForegroundColor Red; exit 1 }
. $modulePath

if (-not (Test-Dependencies)) { return }
$dir = Select-Directory
if (-not $dir) { return }

$targetValue = Get-TestModeInput -Prompt "Enter Description/Comment (e.g., MISSION IMPOSSIBLE)"
Write-Host "`nSetting Description/Comment to: $targetValue" -ForegroundColor Cyan

$files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\\.(mp3|flac)$' }
$ok = 0; $bad = 0
foreach ($file in $files) {
    $success = $false
    if ($file.Extension -eq '.flac' -and $script:metaflacCmd) {
        $success = Write-FlacTag -File $file -TagName "DESCRIPTION" -TagValue $targetValue
    }
    elseif ($file.Extension -eq '.mp3' -and $script:taglibLoaded) {
        try {
            $t = [TagLib.File]::Create($file.FullName)
            $t.Tag.Comment = $targetValue
            $t.Save(); $t.Dispose()
            $success = $true
        } catch {
            $success = $false
        }
    }
    if ($success) { $ok++ } else { $bad++ }
}
Write-Host "Successful: $ok; Failed: $bad" -ForegroundColor Green
