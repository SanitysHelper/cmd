# InputHandler.ps1 - User input handling and validation
# Handles all user input with logging and validation

function Get-UserInput {
    <#
    .SYNOPSIS
    Safe input reading that handles piped input and null gracefully
    Logs all inputs for debugging
    #>
    param([string]$Prompt)
    
    try {
        $userInput = Read-Host -Prompt $Prompt
        if ([string]::IsNullOrWhiteSpace($userInput)) { 
            Write-OperationLog -Operation 'USER_INPUT' -InputValue '<NULL_OR_EMPTY>' -Context $Prompt -Status 'RECEIVED'
            return $null 
        }
        $trimmedInput = $userInput.Trim()
        # Log the input (mask password fields for security)
        $logValue = if ($Prompt -like '*password*') { '<PASSWORD_MASKED>' } else { $trimmedInput }
        Write-OperationLog -Operation 'USER_INPUT' -InputValue $logValue -Context $Prompt -Status 'RECEIVED'
        return $trimmedInput
    } catch {
        Write-OperationLog -Operation 'USER_INPUT' -InputValue '<ERROR>' -Context $Prompt -Status 'FAILED' -Details $_
        return $null
    }
}

function Test-Timeout {
    <#
    .SYNOPSIS
    Check if execution has exceeded timeout limit
    #>
    param([hashtable]$InternalSettings, [DateTime]$StartTime)
    
    if ($InternalSettings.timeout_seconds -le 0) { return $false }
    
    $elapsed = (Get-Date) - $StartTime
    if ($elapsed.TotalSeconds -gt $InternalSettings.timeout_seconds) {
        Write-Host "`n========================================" -ForegroundColor Red
        Write-Host "[ERROR] TIMEOUT EXCEEDED" -ForegroundColor Red
        Write-Host "[ERROR] Program ran for $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Red
        Write-Host "[ERROR] Maximum allowed: $($InternalSettings.timeout_seconds) seconds" -ForegroundColor Red
        Write-Host "[ERROR] Exiting to prevent runaway execution" -ForegroundColor Red
        Write-Host "========================================`n" -ForegroundColor Red
        Write-Log "ERROR: Timeout exceeded after $($elapsed.TotalSeconds) seconds (max: $($InternalSettings.timeout_seconds))" 'ERROR'
        return $true
    }
    return $false
}

Export-ModuleMember -Function Get-UserInput, Test-Timeout
