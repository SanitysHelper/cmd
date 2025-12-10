#Requires -Version 5.0
Set-StrictMode -Version Latest

function Add-TermUIFunctionFromString {
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
