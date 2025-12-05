# Waiter Script - Captures input during timeout window
# Returns value to stdout for batch to capture
# Syntax: .\waiter.ps1 -Timeout 5
# Returns: Character pressed or "C" if timeout

param(
    [int]$Timeout = 5,
    [string]$Default = "C"
)

# Function to read keyboard input with timeout
function Read-InputWithTimeout {
    param(
        [int]$TimeoutSeconds,
        [string]$Default
    )
    
    $endTime = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    
    # Use WaitHandle with a simple approach
    # Check for Console key available
    $originalCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $true
    
    try {
        while ([DateTime]::UtcNow -lt $endTime) {
            # Check if a key is available
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                return $key.KeyChar.ToString().ToUpper()
            }
            
            # Small sleep to avoid CPU spinning
            [System.Threading.Thread]::Sleep(100)
        }
    }
    finally {
        [Console]::CursorVisible = $originalCursorVisible
    }
    
    # Timeout occurred
    return $Default
}

# Get the input
$choice = Read-InputWithTimeout -TimeoutSeconds $Timeout -Default $Default

# Output choice (batch will capture this via FOR /F)
Write-Output $choice

