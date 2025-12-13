#Requires -Version 5.0
Set-StrictMode -Version Latest

function Clear-TermUIButtons {
    param([Parameter(Mandatory)][string]$TermUIRoot)
    # Always use local path for mainUIRoot
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    if (Test-Path $mainUIRoot) {
        Remove-Item $mainUIRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $mainUIRoot -Force | Out-Null
}

function Add-TermUIButton {
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
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][object[]]$Buttons
    )
    
    foreach ($btn in $Buttons) {
        Add-TermUIButton -TermUIRoot $TermUIRoot -Path $btn.Path -Description $btn.Description
    }
}

function Add-TermUIButtonRange {
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
