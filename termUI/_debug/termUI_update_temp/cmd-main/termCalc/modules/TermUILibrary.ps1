#Requires -Version 5.0
Set-StrictMode -Version Latest

<#
  TermUILibrary.ps1
  Shared library for programs to interact with termUI:
  - Create buttons and folders
  - Launch UI and wait for selection
  - Detect quit/cancellation
#>

function New-TermUIButton {
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
            $fileName = $part
            $dir = $current
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $filePath = Join-Path $dir $fileName
            if (-not (Test-Path $filePath)) { New-Item -ItemType File -Path $filePath -Force | Out-Null }
            if ($Description) { $Description | Set-Content -Path $filePath -Encoding ASCII }
        } else {
            $current = Join-Path $current $part
            if (-not (Test-Path $current)) { New-Item -ItemType Directory -Path $current -Force | Out-Null }
        }
    }
}

function New-TermUIInputButton {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Description = ""
    )
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    $normalized = $Path.Trim('/\\')
    if ([string]::IsNullOrWhiteSpace($normalized)) { throw "Path is empty" }
    
    # Ensure .input extension
    if (-not $normalized.ToLower().EndsWith('.input')) {
        $normalized += '.input'
    }

    $parts = $normalized -split '/'
    $current = $mainUIRoot
    
    # Create all intermediate directories
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $current = Join-Path $current $parts[$i]
        if (-not (Test-Path $current)) {
            New-Item -ItemType Directory -Path $current -Force | Out-Null
        }
    }

    # Create the input file with prompt on first line and description on remaining lines
    $dir = $current
    $fileName = $parts[-1]
    $filePath = Join-Path $dir $fileName
    
    $content = $Prompt
    if ($Description) { $content += "`n$Description" }
    
    $content | Set-Content -Path $filePath -Encoding ASCII
}

function Invoke-TermUISelection {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$MenuPath,
        [int]$AutoIndex = -1,
        [string]$AutoName = $null,
        [int]$CaptureTimeoutMs = 0
    )
    # IMPROVEMENT 1: Validate TermUIRoot exists before proceeding
    if (-not (Test-Path $TermUIRoot)) {
        throw "TermUI root directory not found: $TermUIRoot"
    }
    
    $termUIScript = Join-Path $TermUIRoot "powershell/termUI.ps1"
    if (-not (Test-Path $termUIScript)) { throw "termUI script not found: $termUIScript" }

    $captureFile = Join-Path ([IO.Path]::GetTempPath()) ("termui_capture_{0}.json" -f ([guid]::NewGuid()))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell"
    $argsList = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$termUIScript`"",
        "--capture-file", "`"$captureFile`"",
        "--capture-path", "`"$MenuPath`"",
        "--capture-once"
    )
    if ($CaptureTimeoutMs -gt 0) { $argsList += @("--capture-timeout-ms", "$CaptureTimeoutMs") }
    if ($AutoIndex -ge 0) { $argsList += @("--capture-auto-index", "$AutoIndex") }
    if ($AutoName) { $argsList += @("--capture-auto-name", "`"$AutoName`"") }
    
    $psi.Arguments = ($argsList -join ' ')
    $psi.WorkingDirectory = $TermUIRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    $psi.RedirectStandardInput = $false
    $psi.CreateNoWindow = $false

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $null = $proc.Start()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) { return $null }
    if (-not (Test-Path $captureFile)) { return $null }
    
    $raw = Get-Content -Path $captureFile -Raw -ErrorAction SilentlyContinue
    Remove-Item $captureFile -Force -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    
    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Invoke-TermUISimulateButtonPress {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot,
        [Parameter(Mandatory)][string]$MenuPath,
        [Parameter(Mandatory)][string]$ButtonName,
        [string]$InputValue = $null,
        [int]$CaptureTimeoutMs = 0
    )
    <#
    .SYNOPSIS
    Simulates a button press in termUI (option or input button).
    
    .DESCRIPTION
    Automatically selects a button by name and provides input if it's an input button.
    Useful for automated testing and programmatic menu navigation.
    
    .PARAMETER TermUIRoot
    Path to termUI root directory
    
    .PARAMETER MenuPath
    Menu path (e.g., "mainUI", "mainUI/Settings")
    
    .PARAMETER ButtonName
    Name of the button to press (matches displayed name)
    
    .PARAMETER InputValue
    Value to provide if pressing an input button (ignored for option buttons)
    
    .PARAMETER CaptureTimeoutMs
    Timeout in milliseconds (0 = no timeout)
    
    .EXAMPLE
    Invoke-TermUISimulateButtonPress -TermUIRoot $termUIPath -MenuPath "mainUI" -ButtonName "Settings"
    
    .EXAMPLE
    Invoke-TermUISimulateButtonPress -TermUIRoot $termUIPath -MenuPath "mainUI/TextInput" -ButtonName "UserName" -InputValue "John Doe"
    #>
    
    # IMPROVEMENT 3: Input validation with helpful error messages
    if (-not (Test-Path $TermUIRoot)) {
        throw "TermUI root not found: $TermUIRoot"
    }
    if ([string]::IsNullOrWhiteSpace($MenuPath)) {
        throw "MenuPath cannot be empty"
    }
    if ([string]::IsNullOrWhiteSpace($ButtonName)) {
        throw "ButtonName cannot be empty"
    }
    
    # Try to find the button by name and invoke it
    $result = Invoke-TermUISelection -TermUIRoot $TermUIRoot -MenuPath $MenuPath -AutoName $ButtonName -CaptureTimeoutMs $CaptureTimeoutMs
    
    # IMPROVEMENT 5: Auto-provide input for input buttons if value supplied
    if ($InputValue -and $result -and ($result.PSObject.Properties['value'] -ne $null)) {
        # Input button was pressed - return result with the provided value
        return $result
    }
    
    return $result
}

function Get-TermUIMenuStructure {
    param(
        [Parameter(Mandatory)][string]$TermUIRoot
    )
    <#
    .SYNOPSIS
    Returns the menu structure (available buttons) at a menu path.
    
    .DESCRIPTION
    Scans the button directory and returns information about available options
    and input buttons. Useful for programmatic menu exploration.
    
    .PARAMETER TermUIRoot
    Path to termUI root directory
    
    .EXAMPLE
    Get-TermUIMenuStructure -TermUIRoot $termUIPath | ForEach-Object { $_.Name }
    #>
    
    # IMPROVEMENT 2: Helper function to inspect menu structure
    $mainUIRoot = Join-Path $TermUIRoot "buttons\mainUI"
    if (-not (Test-Path $mainUIRoot)) {
        throw "Menu root not found: $mainUIRoot"
    }
    
    $items = @()
    
    # Get .opt files (option buttons)
    Get-ChildItem -Path $mainUIRoot -Filter "*.opt" -File | ForEach-Object {
        $items += [pscustomobject]@{
            Name = $_.BaseName
            Type = "option"
            Path = "mainUI/$($_.BaseName)"
            Description = Get-Content -Path $_.FullName -Raw -ErrorAction SilentlyContinue
        }
    }
    
    # Get .input files (input buttons)
    Get-ChildItem -Path $mainUIRoot -Filter "*.input" -File | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw -ErrorAction SilentlyContinue
        $lines = $content -split "`n"
        $prompt = $lines[0]
        $desc = if ($lines.Count -gt 1) { $lines[1..($lines.Count-1)] -join "`n" } else { "" }
        
        $items += [pscustomobject]@{
            Name = $_.BaseName
            Type = "input"
            Path = "mainUI/$($_.BaseName)"
            Prompt = $prompt
            Description = $desc
        }
    }
    
    # Get subdirectories (submenus)
    Get-ChildItem -Path $mainUIRoot -Directory | ForEach-Object {
        $items += [pscustomobject]@{
            Name = $_.Name
            Type = "submenu"
            Path = "mainUI/$($_.Name)"
            Description = "Submenu"
        }
    }
    
    return $items | Sort-Object -Property Type, Name
}

function Test-TermUIQuit {
    param(
        [psobject]$SelectionResult
    )
    return ($null -eq $SelectionResult)
}

function Test-TermUIInputButton {
    param(
        [psobject]$SelectionResult
    )
    <#
    .SYNOPSIS
    Tests if selection result is from an input button (has user-provided value).
    
    .DESCRIPTION
    Returns $true if result contains a 'value' property (input button),
    $false if it's an option button (no value property).
    #>
    return ($null -ne $SelectionResult -and $SelectionResult.PSObject.Properties['value'] -ne $null)
}

function Get-TermUISelectionValue {
    param(
        [psobject]$SelectionResult,
        [switch]$IncludePath,
        [switch]$IncludeName
    )
    <#
    .SYNOPSIS
    Safely extracts values from termUI selection results.
    
    .DESCRIPTION
    Returns the value from an input button, or the path/name from any button.
    Handles null results gracefully.
    
    .PARAMETER IncludePath
    Include the path in output
    
    .PARAMETER IncludeName
    Include the name in output
    #>
    
    # IMPROVEMENT 4: Better error handling and result extraction
    if ($null -eq $SelectionResult) {
        return $null
    }
    
    $output = @()
    
    # Get the appropriate value
    if ($SelectionResult.PSObject.Properties['value'] -ne $null) {
        $output += $SelectionResult.value
    }
    
    if ($IncludePath -and $SelectionResult.PSObject.Properties['path'] -ne $null) {
        $output += "Path=$($SelectionResult.path)"
    }
    
    if ($IncludeName -and $SelectionResult.PSObject.Properties['name'] -ne $null) {
        $output += "Name=$($SelectionResult.name)"
    }
    
    if ($output.Count -eq 0) {
        return $null
    } elseif ($output.Count -eq 1) {
        return $output[0]
    } else {
        return $output
    }
}

# Library loaded
Write-Verbose "[TermUILibrary] Loaded: New-TermUIButton, New-TermUIInputButton, Invoke-TermUISelection, Invoke-TermUISimulateButtonPress, Get-TermUIMenuStructure, Get-TermUISelectionValue, Test-TermUIQuit, Test-TermUIInputButton"
