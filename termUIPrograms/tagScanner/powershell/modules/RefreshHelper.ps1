#Requires -Version 5.0
<#
.SYNOPSIS
RefreshHelper Module - Provides simple menu refresh capability for termUI programs

.DESCRIPTION
This module provides a simple interface for termUI programs to refresh their menu structure
after making changes to button files. It abstracts the complexity of menu rebuilding.

.NOTES
Used by programs like tagScanner to dynamically update menus without restarting termUI.
#>

function Invoke-TermUIMenuRefresh {
    <#
    .SYNOPSIS
    Simple wrapper to refresh termUI menu after adding/removing buttons.
    
    .DESCRIPTION
    Call this after your program adds new button files to make them appear in the menu.
    Handles all the complexity of menu rebuilding internally.
    
    .EXAMPLE
    # After creating new button files
    Invoke-TermUIMenuRefresh
    
    .NOTES
    Non-blocking operation. Returns immediately after queuing refresh.
    Automatically detects termUI location from environment variables or script location.
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Detect termUI root (local only)
        $termUIRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        if (-not (Test-Path (Join-Path $termUIRoot "powershell/modules/MenuBuilder.ps1"))) {
            Write-Warning "Could not find termUI installation for menu refresh"
            return
        }
        
        # Load required modules
        $menuBuilderPath = Join-Path $termUIRoot "powershell/modules/MenuBuilder.ps1"
        if (Test-Path $menuBuilderPath) {
            . $menuBuilderPath
            
            # Force rebuild of menu tree
            $buttonsPath = Join-Path $termUIRoot "buttons"
            $result = Force-MenuRefresh -RootPath $buttonsPath -ClearCache $true
            
            if ($result) {
                Write-Verbose "termUI menu refresh queued"
            }
        }
    }
    catch {
        Write-Warning "Menu refresh error: $_"
    }
}

Export-ModuleMember -Function @(
    'Invoke-TermUIMenuRefresh'
)
