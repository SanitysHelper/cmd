#Requires -Version 5.0
Set-StrictMode -Version Latest

function Invoke-TermUISelection {
    param(
        [string]$TermUIRoot,
        [string]$MenuPath,
        [int]$AutoIndex = -1,
        [string]$AutoName = $null,
        [int]$CaptureTimeoutMs = 0
    )
    if (-not (Test-Path $TermUIRoot)) { throw "termUI root not found: $TermUIRoot" }
    $termUIScript = Join-Path $TermUIRoot "powershell/termUI.ps1"
    if (-not (Test-Path $termUIScript)) { throw "termUI script not found: $termUIScript" }

    $captureFile = Join-Path ([IO.Path]::GetTempPath()) ("termui_capture_{0}.json" -f ([guid]::NewGuid()))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell"
    $argsList = @(
        "-NoProfile","-ExecutionPolicy","Bypass","-File", "`"$termUIScript`"",
        "--capture-file", "`"$captureFile`"",
        "--capture-path", "`"$MenuPath`"",
        "--capture-once"
    )
    if ($CaptureTimeoutMs -gt 0) { $argsList += @("--capture-timeout-ms", "$CaptureTimeoutMs") }
    if ($AutoIndex -ge 0) { $argsList += @("--capture-auto-index", "$AutoIndex") }
    if ($AutoName) { $argsList += @("--capture-auto-name", "`"$AutoName`"") }
    $psi.Arguments = ($argsList -join ' ')
    $psi.WorkingDirectory = $TermUIRoot
    $psi.UseShellExecute = $false           # stay in same console
    $psi.RedirectStandardOutput = $false    # avoid deadlocks and new windows
    $psi.RedirectStandardError = $false
    $psi.RedirectStandardInput = $false
    $psi.CreateNoWindow = $false            # render UI in current terminal

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $null = $proc.Start()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) { throw "termUI exited with code $($proc.ExitCode)" }

    if (-not (Test-Path $captureFile)) { throw "Capture file not found: $captureFile" }
    $raw = Get-Content -Path $captureFile -Raw
    Remove-Item $captureFile -Force -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Empty capture content" }
    try {
        return $raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse capture JSON: $_"
    }
}
