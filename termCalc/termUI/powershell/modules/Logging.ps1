function Get-Timestamp {
    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Rotate-LogIfNeeded {
    param(
        [string]$Path,
        [int]$LimitBytes
    )
    if (-not (Test-Path $Path)) { return }
    $info = Get-Item $Path
    if ($info.Length -lt $LimitBytes) { return }
    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $archive = Join-Path (Split-Path $Path -Parent) ("{0}.{1}.log" -f [IO.Path]::GetFileNameWithoutExtension($Path), $timestamp)
    Move-Item -Path $Path -Destination $archive -Force -ErrorAction SilentlyContinue
}

function Log-Error {
    param([string]$Message)
    if (-not $script:settings.Logging.log_error) { return }
    $path = Join-Path $script:paths.logs "error.log"
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    "[$(Get-Timestamp)] ERROR: $Message" | Add-Content -Path $path -Encoding UTF8
}

function Log-Important {
    param([string]$Message)
    if (-not $script:settings.Logging.log_important) { return }
    $path = Join-Path $script:paths.logs "important.log"
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    "[$(Get-Timestamp)] INFO: $Message" | Add-Content -Path $path -Encoding UTF8
}

function Log-Input {
    param(
        [string]$Message,
        [string]$Source = "Unknown"
    )
    if (-not $script:settings.Logging.log_input) { return }
    $now = Get-Date
    $delta = ($now - $script:lastInputTime).TotalSeconds
    $script:lastInputTime = $now
    $script:inputCounter++
    $delayTag = if ($delta -gt 2 -and $script:inputCounter -gt 1) { " [DELAY: {0:F2}s - MANUAL INPUT SUSPECTED]" -f $delta } else { "" }
    $path = Join-Path $script:paths.logs "input.log"
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    $logLine = "[{0}] INPUT #{1} [{2}] (+{3:F3}s){4}: {5}" -f (Get-Timestamp), $script:inputCounter, $Source, $delta, $delayTag, $Message
    $logLine | Add-Content -Path $path -Encoding UTF8
}

function Log-InputTiming {
    param(
        [string]$Action,
        [string]$Details = ""
    )
    if (-not $script:settings.Logging.log_input_timing) { return }
    $path = Join-Path $script:paths.logs "input-timing.log"
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    "[$(Get-Timestamp)] $Action | $Details" | Add-Content -Path $path -Encoding UTF8
}

function Log-MenuFrame {
    param(
        [array]$Items,
        [int]$SelectedIndex = 0
    )
    if (-not $script:settings.Logging.log_menu_frame) { return }
    $path = Join-Path $script:paths.logs "menu-frame.log"
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    "[$(Get-Timestamp)] MENU FRAME Selected=$SelectedIndex Count=$($Items.Count)" | Add-Content -Path $path -Encoding UTF8
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $indicator = if ($i -eq $SelectedIndex) { ">>>" } else { "   " }
        $name = $Items[$i].Name
        $type = $Items[$i].Type
        "  $indicator [$($i+1)] ($type) $name" | Add-Content -Path $path -Encoding UTF8
    }
}

function Write-Transcript {
    param([string]$Message)
    if (-not $script:settings.Logging.log_transcript) { return }
    $path = $script:paths.transcript
    Rotate-LogIfNeeded -Path $path -LimitBytes $script:paths.logLimitBytes
    $Message | Add-Content -Path $path -Encoding UTF8
}
