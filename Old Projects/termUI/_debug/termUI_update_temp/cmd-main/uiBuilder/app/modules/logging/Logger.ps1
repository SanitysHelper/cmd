# ============================================================================
# LOGGING MODULE
# ============================================================================
# Provides centralized logging functions for uiBuilder
# All logging respects settings.ini configuration

function Get-Timestamp {
    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Log-Navigation {
    param([string]$Message)
    if (-not $script:settings.Logging.log_navigation) { return }
    $logFile = Join-Path $script:logsPath "navigation.log"
    "[$(Get-Timestamp)] NAVIGATE: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Input {
    param(
        [string]$Message,
        [string]$Source = "Unknown"
    )
    if (-not $script:settings.Logging.log_input) { return }
    
    # Calculate timing
    $currentTime = Get-Date
    $timeSinceLastInput = ($currentTime - $script:lastInputTime).TotalSeconds
    $script:lastInputTime = $currentTime
    $script:inputCounter++
    
    # Detect unusual delays (>2 seconds suggests manual input)
    $delayIndicator = ""
    if ($timeSinceLastInput -gt 2.0 -and $script:inputCounter -gt 1) {
        $delayIndicator = " [DELAY: ${timeSinceLastInput}s - MANUAL INPUT SUSPECTED]"
    }
    
    $logFile = Join-Path $script:logsPath "input.log"
    $timingInfo = "(+${timeSinceLastInput}s)"
    "[$(Get-Timestamp)] INPUT #$($script:inputCounter) [$Source] $timingInfo${delayIndicator}: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Error {
    param([string]$Message)
    if (-not $script:settings.Logging.log_error) { return }
    $logFile = Join-Path $script:logsPath "error.log"
    "[$(Get-Timestamp)] ERROR: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Important {
    param([string]$Message)
    if (-not $script:settings.Logging.log_important) { return }
    $logFile = Join-Path $script:logsPath "important.log"
    "[$(Get-Timestamp)] INFO: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-Debug {
    param([string]$Message)
    if (-not $script:debugMode) { return }
    $logFile = Join-Path $script:logsPath "ui-debug.log"
    "[$(Get-Timestamp)] DEBUG: $Message" | Add-Content -Path $logFile -Encoding UTF8
}

function Log-InputTiming {
    param(
        [string]$Action,
        [string]$Details = ""
    )
    if (-not $script:settings.Logging.log_input) { return }
    
    $logFile = Join-Path $script:logsPath "input-timing.log"
    $timestamp = Get-Timestamp
    "[$timestamp] $Action | $Details" | Add-Content -Path $logFile -Encoding UTF8
}

function Write-Transcript {
    param([string]$Message)
    if (-not $script:settings.Logging.log_transcript) { return }
    $Message | Add-Content -Path $script:transcriptPath -Encoding UTF8
}

function Log-MenuFrame {
    param(
        [array]$Items,
        [int]$SelectedIndex = 0,
        [bool]$IsShiftHeld = $false,
        [bool]$IsEnterHeld = $false
    )
    
    $logFile = Join-Path $script:logsPath "menu-frame.log"
    
    # Check file size and rotate if needed (2MB limit)
    if (Test-Path $logFile) {
        $logSize = (Get-Item $logFile).Length
        if ($logSize -gt 2097152) {  # 2MB in bytes
            $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
            $archiveName = "menu-frame_$timestamp.log"
            $archivePath = Join-Path $script:logsPath $archiveName
            Move-Item -Path $logFile -Destination $archivePath -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Log frame header
    $frameHeader = "[$(Get-Timestamp)] === MENU FRAME === SelectedIdx=$SelectedIndex Shift=$IsShiftHeld Enter=$IsEnterHeld ItemCount=$($Items.Count)"
    $frameHeader | Add-Content -Path $logFile -Encoding UTF8
    
    # Log each menu item
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $indicator = if ($i -eq $SelectedIndex) { ">>>" } else { "   " }
        $itemName = $Items[$i]['Name']
        $itemType = $Items[$i]['Type']
        if ([string]::IsNullOrWhiteSpace($itemType)) { $itemType = 'option' }
        $itemValue = $Items[$i]['Value']
        $valueStr = if (-not [string]::IsNullOrWhiteSpace($itemValue)) { " [value=$itemValue]" } else { "" }
        "  $indicator [$($i+1)] ($itemType) $itemName$valueStr" | Add-Content -Path $logFile -Encoding UTF8
    }
    
    # Log frame footer
    "  ---" | Add-Content -Path $logFile -Encoding UTF8
}

