param([string]$Options, [string]$Title="MENU", [int]$DefaultIndex=0, [int]$TimeoutSeconds=0, [string]$OutputFile, [string]$DebugLogFile)
if (-not $Options) { exit 1 }
$items = $Options -split ';'
if (-not $items -or $items.Length -eq 0) { exit 1 }
$idx = [Math]::Min([Math]::Max($DefaultIndex, 0), $items.Length - 1)
$deadline = if ($TimeoutSeconds -gt 0) { [DateTime]::UtcNow.AddSeconds($TimeoutSeconds) } else { $null }
function Write-Row { param([string]$Text, [bool]$Selected) if ($Selected) { Write-Host "> $Text" -ForegroundColor Cyan } else { Write-Host "  $Text" } }
function Log-Debug { param([string]$Message) if (-not $DebugLogFile) { return } $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"; $dir = Split-Path $DebugLogFile -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }; "$stamp `t $Message" | Out-File -FilePath $DebugLogFile -Append -Encoding ASCII }
try { [Console]::CursorVisible = $false } catch {}
try {
    while ($true) {
        Clear-Host
        if ($Title) { Write-Host $Title; Write-Host "" }
        for ($i = 0; $i -lt $items.Length; $i++) { Write-Row -Text $items[$i] -Selected ($i -eq $idx) }
        if ($deadline -and [DateTime]::UtcNow -gt $deadline) { Log-Debug "Timeout -> $idx"; break }
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'   { $idx = if ($idx -gt 0) { $idx - 1 } else { $items.Length - 1 }; Log-Debug "Up -> $idx" }
                'DownArrow' { $idx = if ($idx -lt $items.Length - 1) { $idx + 1 } else { 0 }; Log-Debug "Down -> $idx" }
                'Enter'     { Log-Debug "Enter -> $idx"; break }
                'Escape'    { Log-Debug "Escape -> $idx"; break }
            }
        } else { Start-Sleep -Milliseconds 100 }
    }
}
finally { try { [Console]::CursorVisible = $true } catch {} }
if ($OutputFile) { $idx | Out-File -FilePath $OutputFile -Encoding ASCII -Force }
exit 0
