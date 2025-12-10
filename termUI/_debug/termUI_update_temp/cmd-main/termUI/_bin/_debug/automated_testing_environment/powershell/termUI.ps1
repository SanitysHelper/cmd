#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Force-real flag clears any lingering test env vars (prevents accidental replay)
$forceReal = $args -contains "--real"
if ($forceReal) {
    $env:TERMUI_TEST_MODE = $null
    $env:TERMUI_TEST_FILE = $null
}

# Track quit requests and handler reference for cleanup
$script:quitRequested = $false
$script:handler = $null
$script:manualInputDetected = $false
$script:isTestEnvironment = $false

$script:paths = @{}
$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:paths.logs = Join-Path $script:scriptDir "..\_debug\logs" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $script:paths.logs) { $script:paths.logs = Join-Path $script:scriptDir "..\_debug\logs" }
$script:paths.transcript = Join-Path $script:paths.logs "ui-transcript.log"
$script:paths.settings = Join-Path $script:scriptDir "..\settings.ini"
$script:paths.menuRoot = $null
$script:lastInputTime = Get-Date
$script:inputCounter = 0

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
    $currentPath = "mainUI"
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
        Write-Host "=== $($script:settings.General.ui_title) ===" -ForegroundColor Cyan
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
        if ($InputBuffer) {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Backspace] Delete  [Escape] Back  [Q] Quit  |  Input: $InputBuffer" -ForegroundColor Yellow
        } else {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit" -ForegroundColor DarkGray
        }
    }

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
        
        # Render menu only when needed (first time or after navigation)
        $needsRender = $true
        if ($needsRender) {
            Log-MenuFrame -Items $items -SelectedIndex $selectedIndex
            Render-Menu -Items $items -Selected $selectedIndex -InputBuffer $numberBuffer
        }

        # Poll for input - wait with timeout to avoid busy spinning
        $inputReceived = $false
        $timeout = 0
        while (-not $inputReceived -and $timeout -lt 1000) {
            $evt = Get-NextInputEvent -Handler $handler
            if ($evt) {
                $inputReceived = $true
                $actionTaken = $false
                $navBack = $false
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
                        if ($items.Count -gt 0) {
                            $numberBuffer = ""  # Clear number buffer on navigation
                            if ($selectedIndex -gt 0) { $selectedIndex-- } else { $selectedIndex = $items.Count - 1 }
                            $actionTaken = $true
                        }
                    }
                    "Down" { 
                        if ($items.Count -gt 0) {
                            $numberBuffer = ""  # Clear number buffer on navigation
                            if ($selectedIndex -lt $items.Count - 1) { $selectedIndex++ } else { $selectedIndex = 0 }
                            $actionTaken = $true
                        }
                    }
                    "Escape" {
                        # If there's input buffer, clear it; otherwise navigate back
                        if ($numberBuffer) {
                            $numberBuffer = ""
                            $navBack = $true
                            $actionTaken = $true
                        } else {
                            $parts = $currentPath -split "/"
                            if ($parts.Count -gt 1) {
                                $currentPath = ($parts[0..($parts.Count-2)] -join "/")
                                $selectedIndex = 0
                                Log-Important "Navigated back to: $currentPath"
                                $navBack = $true
                                $actionTaken = $true
                            }
                        }
                        # If at mainUI root, ignore Escape (don't exit)
                    }
                    "Enter" {
                        # If there's a number buffer, use it for selection
                        if ($numberBuffer) {
                            $targetIndex = [int]$numberBuffer - 1
                            if ($targetIndex -ge 0 -and $targetIndex -lt $items.Count) {
                                $selectedIndex = $targetIndex
                                $item = $items[$selectedIndex]
                            } else {
                                # Invalid number, clear buffer and re-render
                                $numberBuffer = ""
                                $navBack = $true
                                $actionTaken = $true
                                break
                            }
                            $numberBuffer = ""
                        } elseif ($items.Count -gt 0 -and $selectedIndex -lt $items.Count) {
                            $item = $items[$selectedIndex]
                        } else {
                            break
                        }
                        
                        if ($item) {
                            if ($item.Type -eq "submenu") {
                                $currentPath = $item.Path
                                $selectedIndex = 0
                                Log-Important "Entered submenu: $currentPath"
                                $navBack = $true
                                $actionTaken = $true
                            } else {
                                Log-Important "Selected option: $($item.Path)"
                                Write-Transcript "Selected option: $($item.Path)"
                                Write-Host "`n========================================" -ForegroundColor Cyan
                                Write-Host " SELECTED: $($item.Name)" -ForegroundColor Green
                                Write-Host " Path: $($item.Path)" -ForegroundColor Gray
                                Write-Host "========================================" -ForegroundColor Cyan

                                if (-not ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode)) {
                                    Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
                                    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                                }

                                $actionTaken = $true
                                $navBack = $true
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
                            $navBack = $true  # Trigger re-render to show input
                        }
                        # Ignore other characters
                    }
                    "Backspace" {
                        # Remove last digit from buffer
                        if ($numberBuffer.Length -gt 0) {
                            $numberBuffer = $numberBuffer.Substring(0, $numberBuffer.Length - 1)
                            $actionTaken = $true
                            $navBack = $true  # Trigger re-render to show updated input
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
                
                # Break inner loop to redraw menu if navigated
                if ($navBack -or $script:quitRequested) {
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
