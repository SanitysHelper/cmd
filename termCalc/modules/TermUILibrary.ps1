#Requires -Version 5.0
Set-StrictMode -Version Latest

<#
  TermUILibrary.ps1
  Shared library for programs to interact with termUI:
  - Create buttons and folders
  - Launch UI and wait for selection
  - Detect quit/cancellation
#>

function New-TermUIButton {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$Path,
        [string]$Description = ""
    )
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    $normalized = $Path.Trim('/\\')
    if ([string]::IsNullOrWhiteSpace($normalized)) { throw "Path is empty" }

    $parts = $normalized -split '/'
    $current = $mainUIRoot
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        $isLast = ($i -eq $parts.Count - 1)
        if ($isLast -and $part.ToLower().EndsWith('.opt')) {
            $fileName = $part
            $dir = $current
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $filePath = Join-Path $dir $fileName
            if (-not (Test-Path $filePath)) { New-Item -ItemType File -Path $filePath -Force | Out-Null }
            if ($Description) { $Description | Set-Content -Path $filePath -Encoding ASCII }
        } else {
            $current = Join-Path $current $part
            if (-not (Test-Path $current)) { New-Item -ItemType Directory -Path $current -Force | Out-Null }
        }
    }
}

function Invoke-TermUISelection {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$MenuPath,
        [int]$AutoIndex = -1,
        [string]$AutoName = $null,
        [int]$CaptureTimeoutMs = 0
    )
    $termUIScript = Join-Path $TermUIRoot "powershell/termUI.ps1"
    if (-not (Test-Path $termUIScript)) { throw "termUI script not found: $termUIScript" }

    $captureFile = Join-Path ([IO.Path]::GetTempPath()) ("termui_capture_{0}.json" -f ([guid]::NewGuid()))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell"
    $argsList = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$termUIScript`"",
        "--capture-file", "`"$captureFile`"",
        "--capture-path", "`"$MenuPath`"",
        "--capture-once"
    )
    if ($CaptureTimeoutMs -gt 0) { $argsList += @("--capture-timeout-ms", "$CaptureTimeoutMs") }
    if ($AutoIndex -ge 0) { $argsList += @("--capture-auto-index", "$AutoIndex") }
    if ($AutoName) { $argsList += @("--capture-auto-name", "`"$AutoName`"") }
    
    $psi.Arguments = ($argsList -join ' ')
    $psi.WorkingDirectory = $TermUIRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    $psi.RedirectStandardInput = $false
    $psi.CreateNoWindow = $false

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $null = $proc.Start()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) { return $null }
    if (-not (Test-Path $captureFile)) { return $null }
    
    $raw = Get-Content -Path $captureFile -Raw -ErrorAction SilentlyContinue
    Remove-Item $captureFile -Force -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    
    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Test-TermUIQuit {
    param(
        [psobject]$SelectionResult
    )
    return ($null -eq $SelectionResult)
}

# Library loaded
Write-Verbose "[TermUILibrary] Loaded: New-TermUIButton, Invoke-TermUISelection, Test-TermUIQuit"
