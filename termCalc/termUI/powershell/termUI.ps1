#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load version manager for version tracking
$script:moduleDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "modules"
. (Join-Path $script:moduleDir "VersionManager.ps1")

# Check for version/changelog flags
$showVersion = $args -contains "--version" -or $args -contains "-v"
$showChangelog = $args -contains "--changelog" -or $args -contains "-c"

if ($showVersion) {
    Write-Host (Get-TermUIVersionString -TermUIRoot (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
    exit 0
}

if ($showChangelog) {
    Write-Host (Get-TermUIChangelog -TermUIRoot (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
    exit 0
}

# Force-real flag clears any lingering test env vars (prevents accidental replay)
$forceReal = $args -contains "--real"
if ($forceReal) {
    $env:TERMUI_TEST_MODE = $null
    $env:TERMUI_TEST_FILE = $null
}

# Optional capture mode for external callers (e.g., termCalculator)
$captureFile = $null
$capturePath = $null
$captureOnce = $false
$captureAutoIndex = -1
$captureAutoName = $null
$captureTimeoutMs = 0

$argList = @()
foreach ($a in $args) { $argList += $a }
for ($i = 0; $i -lt $argList.Count; $i++) {
    switch ($argList[$i]) {
        "--capture-file" {
            if ($i + 1 -lt $argList.Count) { $captureFile = $argList[$i + 1]; $i++ }
        }
        "--capture-path" {
            if ($i + 1 -lt $argList.Count) { $capturePath = $argList[$i + 1]; $i++ }
        }
        "--capture-once" { $captureOnce = $true }
        "--capture-auto-index" {
            if ($i + 1 -lt $argList.Count) { $captureAutoIndex = [int]$argList[$i + 1]; $i++ }
        }
        "--capture-auto-name" {
            if ($i + 1 -lt $argList.Count) { $captureAutoName = $argList[$i + 1]; $i++ }
        }
        "--capture-timeout-ms" {
            if ($i + 1 -lt $argList.Count) { $captureTimeoutMs = [int]$argList[$i + 1]; $i++ }
        }
    }
}

# Track quit requests and handler reference for cleanup
$script:quitRequested = $false
$script:handler = $null
$script:manualInputDetected = $false
$script:isTestEnvironment = $false

$script:paths = @{}
$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:paths.logs = Join-Path $script:scriptDir "..\_bin\_debug\logs" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $script:paths.logs) { $script:paths.logs = Join-Path $script:scriptDir "..\_bin\_debug\logs" }
$script:paths.transcript = Join-Path $script:paths.logs "ui-transcript.log"
$script:paths.settings = Join-Path $script:scriptDir "..\settings.ini"
$script:paths.menuRoot = $null
$script:lastInputTime = Get-Date
$script:inputCounter = 0

# In capture mode, isolate logs to a temp folder to avoid file locking across processes
if ($captureFile) {
    $script:paths.logs = Join-Path ([IO.Path]::GetTempPath()) ("termui_logs_{0}" -f [guid]::NewGuid())
    $script:paths.transcript = Join-Path $script:paths.logs "ui-transcript.log"
}

# Ensure directories
@($script:paths.logs) | ForEach-Object { if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null } }

# Load modules
. (Join-Path $script:scriptDir "modules\Logging.ps1")
. (Join-Path $script:scriptDir "modules\Settings.ps1")
. (Join-Path $script:scriptDir "modules\MenuBuilder.ps1")
. (Join-Path $script:scriptDir "modules\InputBridge.ps1")

try {
    Write-Host "[DEBUG] Initializing settings..." -ForegroundColor DarkGray
    Initialize-Settings -SettingsPath $script:paths.settings
    Write-Host "[DEBUG] Loading menu tree..." -ForegroundColor DarkGray
    $script:paths.menuRoot = Join-Path (Join-Path $script:scriptDir "..") $script:settings.General.menu_root
    $script:paths.logLimitBytes = 1024 * 1024 * [int]$script:settings.Logging.log_rotation_mb
    $tree = Build-MenuTree -RootPath $script:paths.menuRoot
    $currentPath = if ($capturePath) { $capturePath } else { "mainUI" }
    $captureStart = Get-Date
    $selectedIndex = 0

    # Check if test environment
    $script:isTestEnvironment = (Test-Path "$script:scriptDir\..\..\automated_testing_environment") -or (Test-Path "$script:scriptDir\..\..\..\automated_testing_environment")
    
    # Check if test mode
    $testMode = $env:TERMUI_TEST_MODE -eq "1"
    $testFile = $env:TERMUI_TEST_FILE
    
    if ($testMode -and $testFile -and (Test-Path $testFile)) {
        $handlerPath = Join-Path (Join-Path $script:scriptDir "..") $script:settings.Input.handler_path
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $handlerPath
        $psi.Arguments = "--replay `"$testFile`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $null = $proc.Start()
        
        # Buffer all events immediately before handler exits
        $eventBuffer = [System.Collections.Generic.Queue[object]]::new()
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line) {
                try {
                    $evt = $line | ConvertFrom-Json
                    $eventBuffer.Enqueue($evt)
                } catch {
                    Log-Error "Failed to parse event: $line"
                }
            }
        }
        $proc.WaitForExit()
        
        $handler = [pscustomobject]@{ 
            Process = $proc
            Reader = $null
            EventBuffer = $eventBuffer
            IsTestMode = $true
        }
        Log-Important "Started input handler in TEST mode: $testFile (buffered $($eventBuffer.Count) events)"
    } else {
        # Interactive mode: use embedded input handler logic
        $handler = [pscustomobject]@{ 
            Process = $null
            Reader = $null
            IsInteractive = $true
        }
        Log-Important "Running in interactive mode (no subprocess)"
    }

    $script:handler = $handler
    $numberBuffer = ""

    function Render-Menu {
        param($Items, $Selected, $InputBuffer = "")
        Clear-Host
        $versionStr = ""
        try {
            $versionFile = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) "VERSION.json"
            if (Test-Path $versionFile) {
                $verData = Get-Content -Path $versionFile -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($verData.version) { $versionStr = " v$($verData.version)" }
            }
        } catch {}
        Write-Host "=== $($script:settings.General.ui_title)$versionStr ===" -ForegroundColor Cyan
        Write-Host "Path: $currentPath" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $prefix = if ($i -eq $Selected) { ">" } else { " " }
            $label = $Items[$i].Name
            $type = $Items[$i].Type
            $color = if ($i -eq $Selected) { "Green" } else { "White" }
            Write-Host "$prefix [$($i+1)] ($type) $label" -ForegroundColor $color
        }
        Write-Host ""
        $desc = $null
        if ($Items.Count -gt 0 -and $Selected -ge 0 -and $Selected -lt $Items.Count) {
            $item = $Items[$Selected]
            if ($null -ne $item -and ($item | Get-Member -Name "Description" -ErrorAction SilentlyContinue)) {
                $desc = $item.Description
            }
        }
        if ($desc) {
            Write-Host "Description: $desc" -ForegroundColor Gray
            Write-Host "" -ForegroundColor Gray
        }
        if ($InputBuffer) {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Backspace] Delete  [Escape] Back  [Q] Quit  |  Input: $InputBuffer" -ForegroundColor Yellow
        } else {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit" -ForegroundColor DarkGray
        }
    }

    # Initialize for smart frame rendering (only render on init and after state changes)
    $firstIteration = $true
    
    while ($true) {
        $items = Get-MenuItemsAtPath -Tree $tree -Path $currentPath
        $validItems = @()
        foreach ($it in $items) {
            $hasName = $false; $hasType = $false; $hasPath = $false
            if ($it -is [hashtable]) {
                $hasName = $it.ContainsKey('Name')
                $hasType = $it.ContainsKey('Type')
                $hasPath = $it.ContainsKey('Path')
            } else {
                $hasName = $null -ne $it.PSObject.Properties['Name']
                $hasType = $null -ne $it.PSObject.Properties['Type']
                $hasPath = $null -ne $it.PSObject.Properties['Path']
            }

            if ($it -and $hasName -and $hasType -and $hasPath) {
                $validItems += $it
            } else {
                Log-Error "Invalid menu item encountered at $currentPath (missing Name/Type/Path)"
            }
        }
        $items = $validItems
        if (-not $items -or $items.Count -eq 0) { 
            Log-Error "No items at $currentPath"
            Write-Host "No items found. Press any key to exit..." -ForegroundColor Yellow
            break 
        }
        if ($selectedIndex -ge $items.Count) { $selectedIndex = 0 }
        if ($selectedIndex -lt 0) { $selectedIndex = 0 }

        # Optional timeout for capture mode
        if ($captureFile -and $captureTimeoutMs -gt 0) {
            $elapsed = (Get-Date) - $captureStart
            if ($elapsed.TotalMilliseconds -ge $captureTimeoutMs) {
                throw "Capture timed out after $([int]$elapsed.TotalMilliseconds) ms"
            }
        }
        
        # Render menu only when needed (first time or after navigation)
        $needsRender = $true
        if ($needsRender) {
            # BUG FIX #2 & #5: Log frame with currentPath for context before rendering
            Log-MenuFrame -Items $items -SelectedIndex $selectedIndex -CurrentPath $currentPath
            Render-Menu -Items $items -Selected $selectedIndex -InputBuffer $numberBuffer
        }

        # Auto-select support for capture mode
        $autoSelected = $false
        if ($captureFile -and ($captureAutoIndex -ge 0 -or $captureAutoName)) {
            $target = $null
            if ($captureAutoName) {
                $target = $items | Where-Object { $_.Name -eq $captureAutoName } | Select-Object -First 1
            }
            if (-not $target -and $captureAutoIndex -ge 0 -and $captureAutoIndex -lt $items.Count) {
                $target = $items[$captureAutoIndex]
            }
            if ($target) {
                $evt = [pscustomobject]@{ key = "Enter"; itemOverride = $target }
                $autoSelected = $true
            }
        }

        # Poll for input - wait with timeout to avoid busy spinning (skipped if auto-selected)
        $inputReceived = $autoSelected
        $timeout = 0
        while (-not $inputReceived -and $timeout -lt 1000) {
            $evt = Get-NextInputEvent -Handler $handler
            if ($evt) {
                $inputReceived = $true
                $actionTaken = $false
                $needsRender = $false  # Only render if input causes a state change
                $selectOption = $false

                switch ($evt.key) {
                    "P" {
                        # P key = Problem: Manual input detected during automated testing
                        if ($script:isTestEnvironment -or $handler.PSObject.Properties['IsInteractive']) {
                            $script:manualInputDetected = $true
                            Log-Important "*** CRITICAL: Manual input detected (P pressed) during automated environment ***"
                            Log-Important "*** This indicates the program was HANGING and waiting for manual keypresses ***"
                            Log-Important "*** The program should handle automated input gracefully without user interaction ***"
                            Write-Host "`n" -ForegroundColor Red
                            Write-Host "========================================================================" -ForegroundColor Red
                            Write-Host "CRITICAL ERROR: Manual Input Required" -ForegroundColor Red
                            Write-Host "" -ForegroundColor Red
                            Write-Host "The program was blocked waiting for your keypress." -ForegroundColor Red
                            Write-Host "This is a CRITICAL BUG in automated input handling." -ForegroundColor Red
                            Write-Host "" -ForegroundColor Red
                            Write-Host "Root Cause: Missing ReadKey() null check or try-catch block" -ForegroundColor Red
                            Write-Host "Location: Check these areas:" -ForegroundColor Red
                            Write-Host "  1. ReadKey() calls without IsTestMode check" -ForegroundColor Red
                            Write-Host "  2. Read-Host calls without proper error handling" -ForegroundColor Red
                            Write-Host "  3. Input operations not wrapped in try-catch blocks" -ForegroundColor Red
                            Write-Host "" -ForegroundColor Red
                            Write-Host "Expected: Program should accept piped/automated input only" -ForegroundColor Red
                            Write-Host "Actual: Program blocked waiting for manual keystroke" -ForegroundColor Red
                            Write-Host "========================================================================" -ForegroundColor Red
                            Write-Host ""
                            $script:quitRequested = $true
                            break
                        }
                    }
                    "Q" {
                        Log-Important "User quit with Q key (handler-mapped)"
                        $script:quitRequested = $true
                        $actionTaken = $true
                        break
                    }
                    "Up" { 
                        # BUG FIX #4: Always set actionTaken for input timing logging
                        $actionTaken = $true
                        if ($items.Count -gt 0) {
                            $numberBuffer = ""  # Clear number buffer on navigation
                            if ($selectedIndex -gt 0) { $selectedIndex-- } else { $selectedIndex = $items.Count - 1 }
                            $needsRender = $true
                        }
                    }
                    "Down" { 
                        # BUG FIX #4: Always set actionTaken for input timing logging
                        $actionTaken = $true
                        if ($items.Count -gt 0) {
                            $numberBuffer = ""  # Clear number buffer on navigation
                            if ($selectedIndex -lt $items.Count - 1) { $selectedIndex++ } else { $selectedIndex = 0 }
                            $needsRender = $true
                        }
                    }
                    "Escape" {
                        # BUG FIX #1 & #3: Always set actionTaken for proper logging and validate path
                        # If there's input buffer, clear it; otherwise navigate back
                        if ($numberBuffer) {
                            $numberBuffer = ""
                            $needsRender = $true
                            $actionTaken = $true
                        } else {
                            # Validate path construction: remove empty parts
                            $parts = @($currentPath -split "/" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                            if ($parts.Count -gt 1) {
                                $currentPath = ($parts[0..($parts.Count-2)] -join "/")
                                $selectedIndex = 0
                                Log-Important "Navigated back to: $currentPath"
                                $needsRender = $true
                                $actionTaken = $true
                            } else {
                                # At root - still mark as action taken for proper logging
                                $actionTaken = $true
                            }
                        }
                    }
                    "Enter" {
                        # If auto-selected, use provided target
                        if ($evt.PSObject.Properties['itemOverride']) {
                            $item = $evt.itemOverride
                            $selectedIndex = 0
                        } else {
                            if ($numberBuffer) {
                                $targetIndex = [int]$numberBuffer - 1
                                if ($targetIndex -ge 0 -and $targetIndex -lt $items.Count) {
                                    $selectedIndex = $targetIndex
                                    $item = $items[$selectedIndex]
                                } else {
                                    $numberBuffer = ""
                                    $needsRender = $true
                                    $actionTaken = $true
                                    break
                                }
                                $numberBuffer = ""
                            } elseif ($items.Count -gt 0 -and $selectedIndex -lt $items.Count) {
                                $item = $items[$selectedIndex]
                            } else {
                                break
                            }
                        }
                        
                        if ($item) {
                            if ($item.Type -eq "submenu") {
                                $currentPath = $item.Path
                                $selectedIndex = 0
                                Log-Important "Entered submenu: $currentPath"
                                $needsRender = $true
                                $actionTaken = $true
                            } elseif ($item.Type -eq "input") {
                                # Handle input button - prompt user for value
                                Write-Host ""
                                $prompt = if ($item.PSObject.Properties['Prompt']) { $item.Prompt } else { "Enter value" }
                                $inputValue = Read-Host -Prompt $prompt
                                
                                Log-Important "Input button '$($item.Name)' received: $inputValue"
                                Write-Transcript "Input button: $($item.Path) = $inputValue"
                                
                                if ($captureFile) {
                                    try {
                                        $parentDir = Split-Path $captureFile -Parent
                                        if ($parentDir -and -not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
                                        @{ name = $item.Name; path = $item.Path; value = $inputValue } | ConvertTo-Json | Set-Content -Path $captureFile -Encoding ASCII
                                        Log-Important "Capture saved to $captureFile"
                                    } catch {
                                        Log-Error "Failed to write capture file: $_"
                                    }
                                }

                                Write-Host "`n========================================" -ForegroundColor Cyan
                                Write-Host " INPUT: $($item.Name)" -ForegroundColor Green
                                Write-Host " Value: $inputValue" -ForegroundColor Yellow
                                Write-Host " Path: $($item.Path)" -ForegroundColor Gray
                                Write-Host "========================================" -ForegroundColor Cyan

                                $skipPause = ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode) -or $captureFile
                                if (-not $skipPause) {
                                    Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
                                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                                }

                                $actionTaken = $true
                                $needsRender = $true
                                if ($captureOnce) { $script:quitRequested = $true; break }
                                if (-not $script:settings.General.keep_open_after_selection) { 
                                    $script:quitRequested = $true
                                    break 
                                }
                            } else {
                                Log-Important "Selected option: $($item.Path)"
                                Write-Transcript "Selected option: $($item.Path)"

                                if ($captureFile) {
                                    try {
                                        $parentDir = Split-Path $captureFile -Parent
                                        if ($parentDir -and -not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
                                        @{ name = $item.Name; path = $item.Path } | ConvertTo-Json | Set-Content -Path $captureFile -Encoding ASCII
                                        Log-Important "Capture saved to $captureFile"
                                    } catch {
                                        Log-Error "Failed to write capture file: $_"
                                    }
                                }

                                Write-Host "`n========================================" -ForegroundColor Cyan
                                Write-Host " SELECTED: $($item.Name)" -ForegroundColor Green
                                Write-Host " Path: $($item.Path)" -ForegroundColor Gray
                                Write-Host "========================================" -ForegroundColor Cyan

                                $skipPause = ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode) -or $captureFile
                                if (-not $skipPause) {
                                    Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
                                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                                }

                                $actionTaken = $true
                                $needsRender = $true
                                if ($captureOnce) { $script:quitRequested = $true; break }
                                if (-not $script:settings.General.keep_open_after_selection) { 
                                    $script:quitRequested = $true
                                    break 
                                }
                            }
                        }
                    }
                    "Char" {
                        if ($evt.char -eq "q" -or $evt.char -eq "Q") {
                            Log-Important "User quit with Q key"
                            $script:quitRequested = $true
                            $actionTaken = $true
                            break
                        }
                        # Check if it's a digit (0-9)
                        if ($evt.char -match '^[0-9]$') {
                            $numberBuffer += $evt.char
                            $actionTaken = $true
                            $needsRender = $true  # Trigger re-render to show input
                        }
                        # Ignore other characters
                    }
                    "Backspace" {
                        # Remove last digit from buffer
                        if ($numberBuffer.Length -gt 0) {
                            $numberBuffer = $numberBuffer.Substring(0, $numberBuffer.Length - 1)
                            $actionTaken = $true
                            $needsRender = $true  # Trigger re-render to show updated input
                        }
                    }
                    default {
                        # Ignore unrecognized keys
                    }
                }
                
                # Log only if action was taken
                if ($actionTaken) {
                    Log-Input -Message ($evt | ConvertTo-Json -Compress) -Source "handler"
                    Log-InputTiming -Action "INPUT_ACTION" -Details "$($evt.key)"
                }
                
                # Render menu if needed, then break inner loop
                if ($needsRender) {
                    # BUG FIX #2 & #5: Log frame with currentPath for context before rendering
                    Log-MenuFrame -Items $items -SelectedIndex $selectedIndex -CurrentPath $currentPath
                    Render-Menu -Items $items -Selected $selectedIndex -InputBuffer $numberBuffer
                }
                
                if ($needsRender -or $script:quitRequested) {
                    break
                }
            } else {
                # No input available - sleep and retry
                [System.Threading.Thread]::Sleep(50)
                $timeout += 50
            }
        }

        if ($script:quitRequested) { break }
    }
}
catch {
    Log-Error "$_"
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Stop-InputHandler -Handler $script:handler
    
    # Report if manual input was detected
    if ($script:manualInputDetected) {
        Write-Host "`n[FAILURE] Test detected manual input requirement. See log for details." -ForegroundColor Red
        exit 1
    }
}

