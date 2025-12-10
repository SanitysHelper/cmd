#Requires -Version 5.0

<#
.SYNOPSIS
uiBuilder - PowerShell General UI Menu Builder
A hierarchical menu system for building interactive user interfaces compatible with multiple programs.

.DESCRIPTION
Creates numbered or interactive menus from a CSV button list with submenu support, 
piped input handling, and multi-language code stub generation.

MODULAR ARCHITECTURE:
- modules/logging/Logger.ps1 - Centralized logging functions
- modules/data/DataManager.ps1 - Button list CSV I/O, settings, validation
- modules/ui/MenuDisplay.ps1 - Interactive and numbered menu display
- modules/commands/CommandHandlers.ps1 - CLI commands and main loop

.PARAMETER --debug
Enable debug mode with UI state logging

.PARAMETER --debug-menu <path>
Jump directly to specific menu path (e.g., mainUI.settings)

.PARAMETER --debug-select <index>
Simulate selecting option at index N

.PARAMETER --debug-key <key>
Simulate key press (Up, Down, Enter, Escape, Shift)

.PARAMETER add <name> <description> <path> <type>
Add new button to menu

.PARAMETER remove <path>
Remove button by path

.PARAMETER list
List all buttons

.PARAMETER --generate-stub <language>
Generate code stub for language (ps1, bat, py, cs)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# SCRIPT INITIALIZATION
# ============================================================================

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:buttonListPath = Join-Path $script:scriptDir "button.list"
$script:settingsPath = Join-Path $script:scriptDir "settings.ini"
$script:debugPath = Join-Path $script:scriptDir "_debug"
$script:logsPath = Join-Path $script:debugPath "logs"
$script:runSpacePath = Join-Path $script:scriptDir "run_space"
$script:transcriptPath = Join-Path $script:logsPath "ui-transcript.log"

# Ensure directories exist
@($script:logsPath, $script:runSpacePath) | ForEach-Object { 
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

$script:buttonIndex = @{}
$script:settings = @{}
$script:debugMode = $false
$script:debugMenuPath = $null
$script:debugSelectIndex = $null
$script:currentPath = "mainUI"
$script:breadcrumb = @("mainUI")
$script:keepOpenAfterSelection = $true
$script:autoClose = $false
$script:debugSequenceIndex = $null
$script:debugKeySequence = @()
$script:lastInputTime = Get-Date
$script:inputCounter = 0
$script:aiInputSource = $true

# ============================================================================
# LOAD MODULES
# ============================================================================

$modulesPath = Join-Path $script:scriptDir "modules"

# Import modules using dot-sourcing (not Import-Module) to share script scope
. (Join-Path $modulesPath "logging\Logger.ps1")
. (Join-Path $modulesPath "data\DataManager.ps1")
. (Join-Path $modulesPath "ui\KeyboardHandler.ps1")  # Load keyboard handler before MenuDisplay
. (Join-Path $modulesPath "ui\MenuDisplay.ps1")
. (Join-Path $modulesPath "commands\CommandHandlers.ps1")

# ============================================================================
# ENTRY POINT
# ============================================================================

try {
    Initialize-Settings
    Initialize-ButtonIndex
    Log-Important "Env UIB_INJECT_KEY: $($env:UIB_INJECT_KEY)"
    
    # Parse command line arguments
    if ($args.Count -eq 0) {
        # Interactive mode
        Invoke-MainLoop
    } else {
        # CLI mode
        $command = $args[0].ToLower()
        
        switch ($command) {
            "add" {
                if ($args.Count -lt 5) {
                    Write-Host "Usage: add <name> <description> <path> <type>"
                    exit 1
                }
                exit (Invoke-AddButton -Name $args[1] -Description $args[2] -Path $args[3] -Type $args[4])
            }
            
            "remove" {
                if ($args.Count -lt 2) {
                    Write-Host "Usage: remove <path>"
                    exit 1
                }
                exit (Invoke-RemoveButton -Path $args[1])
            }
            
            "list" {
                Invoke-ListButtons
                exit 0
            }
            
            "--generate-stub" {
                if ($args.Count -lt 2) {
                    Write-Host "Usage: --generate-stub <language>"
                    exit 1
                }
                $stub = Get-LanguageStub -Language $args[1]
                if ($stub) {
                    Write-Host $stub
                    exit 0
                } else {
                    exit 1
                }
            }
            
            "--debug" {
                $script:debugMode = $true
                Log-Important "Debug mode enabled"
                Invoke-MainLoop
            }
            
            default {
                Write-Host "Unknown command: $command"
                exit 1
            }
        }
    }
}
catch {
    Log-Error "$($_.Exception.Message) at $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    exit 1
}
