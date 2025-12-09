# Logging.ps1 - Logging functions for Settings Manager
# Handles all logging operations with timestamps and context

function Write-Log {
    <#
    .SYNOPSIS
    Writes log entries to important.log with timestamps
    #>
    param([string]$Message, [string]$Type = 'INFO')
    
    $logFile = Join-Path $script:LogDir 'important.log'
    if (-not $script:InternalSettings.log_changes) { return }
    
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    "[$stamp] [$Type] $Message" | Out-File -FilePath $logFile -Encoding ASCII -Append -ErrorAction SilentlyContinue
}

function Write-OperationLog {
    <#
    .SYNOPSIS
    Enhanced logging for input/output operations with detailed context
    #>
    param(
        [string]$Operation,
        [string]$InputValue = '',
        [string]$OutputPath = '',
        [string]$Context = '',
        [string]$Status = 'SUCCESS',
        [string]$Details = ''
    )
    
    $logMessage = "OPERATION=$Operation | INPUT=$InputValue | OUTPUT=$OutputPath | CONTEXT=$Context | STATUS=$Status | DETAILS=$Details"
    Write-Log $logMessage 'OPERATION'
}

Export-ModuleMember -Function Write-Log, Write-OperationLog
