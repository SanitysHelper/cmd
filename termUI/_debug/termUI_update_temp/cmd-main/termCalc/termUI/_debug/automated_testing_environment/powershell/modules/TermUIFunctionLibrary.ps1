#Requires -Version 5.0
Set-StrictMode -Version Latest

<#
  TermUIFunctionLibrary.ps1
  Attach scripts/code to buttons for execution when selected.
  Supports multiple languages: PowerShell, Batch, Python, JavaScript, etc.
#>

function Add-TermUIFunctionFromString {
    <#
    .SYNOPSIS
        Attach a script to a button by providing code as a string.
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER ButtonPath
        Full path to the button: "Calculator/ValueA/5.opt" or "Tools/Backup/daily.opt"
    .PARAMETER Code
        Script code to attach.
    .PARAMETER Language
        Script language: "powershell", "batch", "python", "javascript", "bash", etc.
    .EXAMPLE
        $code = @'
        Write-Host "You selected 5"
        '@
        Add-TermUIFunctionFromString -TermUIRoot $root -ButtonPath "Calculator/ValueA/5.opt" `
            -Code $code -Language "powershell"
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$ButtonPath,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Language
    )
    
    $Language = $Language.ToLower().Trim()
    $ext = Get-ScriptExtension -Language $Language
    if (-not $ext) { throw "Unsupported language: $Language" }

    # Extract button name from path (e.g., "5" from "Calculator/ValueA/5.opt")
    $buttonName = [System.IO.Path]::GetFileNameWithoutExtension($ButtonPath)
    $scriptName = "$buttonName.$ext"

    # Create script file in same directory as button
    $buttonDir = Split-Path (Join-Path $TermUIRoot "buttons/mainUI/$ButtonPath")
    $scriptPath = Join-Path $buttonDir $scriptName

    Write-Verbose "[TermUIFunction] Creating function script: $scriptPath"
    $Code | Set-Content -Path $scriptPath -Encoding UTF8
}

function Add-TermUIFunctionFromFile {
    <#
    .SYNOPSIS
        Attach a script to a button by reading from a file.
        Auto-detects language from file extension.
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER ButtonPath
        Full path to the button: "Calculator/ValueA/5.opt"
    .PARAMETER ScriptFile
        Path to script file. Extension determines language (.ps1, .bat, .py, .js, etc.)
    .EXAMPLE
        Add-TermUIFunctionFromFile -TermUIRoot $root -ButtonPath "Tools/Backup/daily.opt" `
            -ScriptFile "C:\scripts\backup_daily.ps1"
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$ButtonPath,
        [Parameter(Mandatory)][string]$ScriptFile
    )
    
    if (-not (Test-Path $ScriptFile)) { throw "Script file not found: $ScriptFile" }
    
    # Auto-detect language from extension
    $ext = [System.IO.Path]::GetExtension($ScriptFile).TrimStart('.')
    $language = Get-LanguageFromExtension -Extension $ext
    if (-not $language) { throw "Unknown script extension: $ext" }

    Write-Verbose "[TermUIFunction] Reading script: $ScriptFile (detected: $language)"
    $code = Get-Content -Path $ScriptFile -Raw
    
    Add-TermUIFunctionFromString -TermUIRoot $TermUIRoot -ButtonPath $ButtonPath `
        -Code $code -Language $language
}

function Get-ScriptExtension {
    <#
    .SYNOPSIS
        Map language name to script extension.
    .PARAMETER Language
        Language name (case-insensitive).
    #>
    param([string]$Language)
    
    $Language = $Language.ToLower().Trim()
    $map = @{
        "powershell" = "ps1"
        "pwsh" = "ps1"
        "batch" = "bat"
        "cmd" = "bat"
        "python" = "py"
        "py" = "py"
        "javascript" = "js"
        "js" = "js"
        "bash" = "sh"
        "sh" = "sh"
        "ruby" = "rb"
        "rb" = "rb"
        "perl" = "pl"
        "vbscript" = "vbs"
        "vbs" = "vbs"
        "lua" = "lua"
        "go" = "go"
        "rust" = "rs"
    }
    
    return $map[$Language]
}

function Get-LanguageFromExtension {
    <#
    .SYNOPSIS
        Map script extension to language name.
    .PARAMETER Extension
        File extension (without dot).
    #>
    param([string]$Extension)
    
    $Extension = $Extension.ToLower().Trim('.')
    $map = @{
        "ps1" = "powershell"
        "bat" = "batch"
        "cmd" = "batch"
        "py" = "python"
        "js" = "javascript"
        "sh" = "bash"
        "rb" = "ruby"
        "pl" = "perl"
        "vbs" = "vbscript"
        "lua" = "lua"
        "go" = "go"
        "rs" = "rust"
    }
    
    return $map[$Extension]
}

function Invoke-TermUIFunction {
    <#
    .SYNOPSIS
        Execute a function script attached to a button.
    .PARAMETER ButtonPath
        Full path including the button name and script.
        Example: "C:\termUI\buttons\mainUI\Calculator\ValueA\5.ps1"
    .PARAMETER Arguments
        Optional arguments to pass to the script.
    #>
    param(
        [Parameter(Mandatory)][string]$ButtonPath,
        [string[]]$Arguments = @()
    )
    
    if (-not (Test-Path $ButtonPath)) { throw "Button function not found: $ButtonPath" }
    
    $ext = [System.IO.Path]::GetExtension($ButtonPath).TrimStart('.')
    $language = Get-LanguageFromExtension -Extension $ext
    
    Write-Verbose "[TermUIFunction] Executing ($language): $ButtonPath"
    
    switch ($language) {
        "powershell" {
            & $ButtonPath @Arguments
        }
        "batch" {
            cmd /c $ButtonPath $Arguments
        }
        "python" {
            python $ButtonPath @Arguments
        }
        "javascript" {
            node $ButtonPath @Arguments
        }
        "bash" {
            bash $ButtonPath @Arguments
        }
        default {
            throw "Cannot execute language: $language"
        }
    }
}

# Library loaded
Write-Verbose "[TermUIFunctionLibrary] Loaded: Add-TermUIFunctionFromString, Add-TermUIFunctionFromFile, Invoke-TermUIFunction"
