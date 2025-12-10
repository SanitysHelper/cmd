#Requires -Version 5.0
Set-StrictMode -Version Latest

<#
  TermUIButtonLibrary.ps1
  Simplified button creation for termUI programs.
  Provides high-level functions to clear and build button menus.
#>

function Clear-TermUIButtons {
    <#
    .SYNOPSIS
        Clear all buttons from termUI mainUI folder.
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    #>
    param([Parameter(Mandatory)][string]$TermUIRoot)
    
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    if (Test-Path $mainUIRoot) {
        Remove-Item $mainUIRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $mainUIRoot -Force | Out-Null
}

function Add-TermUIButton {
    <#
    .SYNOPSIS
        Add a single button or folder structure to termUI.
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER Path
        Button path: "SettingName.opt" or "Folder/SubFolder/ButtonName.opt"
    .PARAMETER Description
        Hover text to display when user selects this button.
    .EXAMPLE
        Add-TermUIButton -TermUIRoot "C:\termUI" -Path "Settings/Logging/debug.opt" -Description "Enable debug mode"
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$Path,
        [string]$Description = ""
    )
    
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    $normalized = $Path.Trim('/\\')
    if ([string]::IsNullOrWhiteSpace($normalized)) { throw "Path is empty" }

    $parts = $normalized -split '/'
    $current = $mainUIRoot
    
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        $isLast = ($i -eq $parts.Count - 1)
        
        if ($isLast -and $part.ToLower().EndsWith('.opt')) {
            # Create .opt file with description
            $dir = $current
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $filePath = Join-Path $dir $part
            if (-not (Test-Path $filePath)) { New-Item -ItemType File -Path $filePath -Force | Out-Null }
            if ($Description) { $Description | Set-Content -Path $filePath -Encoding ASCII }
        } else {
            # Create folder
            $current = Join-Path $current $part
            if (-not (Test-Path $current)) { New-Item -ItemType Directory -Path $current -Force | Out-Null }
        }
    }
}

function Add-TermUIButtonBatch {
    <#
    .SYNOPSIS
        Add multiple buttons at once.
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER Buttons
        Array of @{Path="..."; Description="..."} objects.
    .EXAMPLE
        $buttons = @(
            @{Path="Settings/debug.opt"; Description="Debug mode"},
            @{Path="Tools/backup.opt"; Description="Backup data"}
        )
        Add-TermUIButtonBatch -TermUIRoot "C:\termUI" -Buttons $buttons
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][object[]]$Buttons
    )
    
    foreach ($btn in $Buttons) {
        Add-TermUIButton -TermUIRoot $TermUIRoot -Path $btn.Path -Description $btn.Description
    }
}

function Add-TermUIButtonRange {
    <#
    .SYNOPSIS
        Add buttons for a range of values (e.g., numbers 0-20).
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER Folder
        Parent folder: "Values" creates "Values/0.opt", "Values/1.opt", etc.
    .PARAMETER Values
        Array of values to create: @(0,1,2,5,10,20)
    .PARAMETER DescriptionTemplate
        Template for descriptions: "Set to {0}" becomes "Set to 5" for value 5.
    .EXAMPLE
        Add-TermUIButtonRange -TermUIRoot "C:\termUI" -Folder "Calculator/ValueA" `
            -Values @(0,1,2,5,10,20) -DescriptionTemplate "A = {0}"
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$Folder,
        [Parameter(Mandatory)][object[]]$Values,
        [string]$DescriptionTemplate = "Value: {0}"
    )
    
    foreach ($val in $Values) {
        $path = "$Folder/$val.opt"
        $desc = $DescriptionTemplate -f $val
        Add-TermUIButton -TermUIRoot $TermUIRoot -Path $path -Description $desc
    }
}

function Add-TermUIButtonChoice {
    <#
    .SYNOPSIS
        Add buttons for choice options (like operations or modes).
    .PARAMETER TermUIRoot
        Path to termUI root directory.
    .PARAMETER Folder
        Parent folder: "Operation" creates "Operation/add.opt", etc.
    .PARAMETER Choices
        Hashtable: @{"add"="Add two numbers"; "subtract"="Subtract"}
    .EXAMPLE
        $ops = @{"add"="Add two numbers"; "subtract"="Subtract"; "multiply"="Multiply"}
        Add-TermUIButtonChoice -TermUIRoot "C:\termUI" -Folder "Calculator/Operation" -Choices $ops
    #>
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$Folder,
        [Parameter(Mandatory)][hashtable]$Choices
    )
    
    foreach ($choice in $Choices.GetEnumerator()) {
        $path = "$Folder/$($choice.Key).opt"
        Add-TermUIButton -TermUIRoot $TermUIRoot -Path $path -Description $choice.Value
    }
}

# Library loaded
Write-Verbose "[TermUIButtonLibrary] Loaded: Clear-TermUIButtons, Add-TermUIButton, Add-TermUIButtonBatch, Add-TermUIButtonRange, Add-TermUIButtonChoice"
