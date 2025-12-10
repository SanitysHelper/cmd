# Settings-Manager.ps1 - Main orchestrator (minimal, loads modules)
# This is called by the C# GUI to perform operations

param(
    [string]$Operation,
    [hashtable]$Parameters = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Determine base directory
$script:BaseDir = Split-Path -Parent $PSCommandPath
$script:ModulesDir = Join-Path $BaseDir 'modules'
$script:ConfigDir = Join-Path $ModulesDir 'config'
$script:PSModulesDir = Join-Path $ModulesDir 'powershell'

# Set up paths
$script:SettingsFile = Join-Path $ConfigDir 'settings.ini'
$script:InternalConfig = Join-Path $ConfigDir '.internal_config'
$script:LogDir = Join-Path $BaseDir '_debug\logs'
$script:LogFile = Join-Path $LogDir 'important.log'

# Ensure directories exist
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $ConfigDir -Force -ErrorAction SilentlyContinue

# Load modules explicitly (secure approach)
$modulesToLoad = @(
    'Logging.ps1'
    'SettingsIO.ps1'
    'FileWatcher.ps1'
    'InputHandler.ps1'
    'Cleanup.ps1'
)

foreach ($module in $modulesToLoad) {
    $modulePath = Join-Path $PSModulesDir $module
    if (Test-Path $modulePath) {
        . $modulePath
    } else {
        Write-Warning "Module not found: $module"
    }
}

# Initialize internal settings
$script:InternalSettings = @{
    auto_generate_readme = $true
    log_changes = $true
    backup_on_save = $false
    validate_sections = $true
    allowed_sections = @('General', 'Logging', 'Advanced')
    debug_mode = $false
    timeout_seconds = 300
    admin_password = 'admin'
}

# Script variables
$script:StartTime = Get-Date
$script:CleanupExecuted = $false
$script:FileWatcher = $null
$script:LastModifiedTime = $null

# Load internal config
if (Test-Path $InternalConfig) {
    try {
        $configLines = Get-Content $InternalConfig -ErrorAction SilentlyContinue
        foreach ($line in $configLines) {
            if ($line -match '^([^=]+)=(.+?)(?:\s*#.*)?$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                if ($key -eq 'allowed_sections') {
                    $script:InternalSettings[$key] = $value -split ',' | ForEach-Object { $_.Trim() }
                } elseif ($value -ieq 'true') {
                    $script:InternalSettings[$key] = $true
                } elseif ($value -ieq 'false') {
                    $script:InternalSettings[$key] = $false
                } else {
                    $script:InternalSettings[$key] = $value
                }
            }
        }
    } catch {
        # Use defaults
    }
}

# Export operation function for C# to call
function Invoke-SettingsOperation {
    param(
        [string]$Operation,
        [hashtable]$Params = @{}
    )
    
    switch ($Operation) {
        'LoadSettings' {
            return Load-Settings -SettingsFile $script:SettingsFile
        }
        'SaveSettings' {
            Save-Settings -Settings $Params.Settings -SettingsFile $script:SettingsFile
        }
        'InitializeWatcher' {
            Initialize-FileWatcher -SettingsFile $script:SettingsFile -ScriptDir $script:BaseDir
        }
        'CheckFileChanged' {
            return Test-SettingsFileChanged -SettingsFile $script:SettingsFile
        }
        'UpdateModifiedTime' {
            Update-LastModifiedTime -SettingsFile $script:SettingsFile
        }
        'Cleanup' {
            Invoke-Cleanup -ScriptDir $script:BaseDir -InternalSettings $script:InternalSettings
        }
        default {
            Write-Error "Unknown operation: $Operation"
        }
    }
}

# If called directly with operation parameter
if ($Operation) {
    Invoke-SettingsOperation -Operation $Operation -Params $Parameters
}

Export-ModuleMember -Function Invoke-SettingsOperation
