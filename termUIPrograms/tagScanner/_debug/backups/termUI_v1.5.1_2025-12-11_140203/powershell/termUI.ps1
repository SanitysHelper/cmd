#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Bootstrap metadata
$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:termUIRoot = Split-Path -Parent $script:scriptDir
$script:moduleDir = Join-Path $script:scriptDir "modules"

# Remove any leftover update temp artifacts from previous runs
function Cleanup-UpdateTemp {
    try {
        $debugDir = Join-Path $script:termUIRoot "_debug"
        $tempZip = Join-Path $debugDir "termUI_update.zip"
        $tempExtract = Join-Path $debugDir "termUI_update_temp"
        if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tempExtract) { Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
    } catch {
        # Non-blocking cleanup
    }
}

Cleanup-UpdateTemp

# Core paths required for a healthy install (used for bootstrap/repair)
$script:requiredPaths = @(
    (Join-Path $script:moduleDir "Logging.ps1"),
    (Join-Path $script:moduleDir "Settings.ps1"),
    (Join-Path $script:moduleDir "MenuBuilder.ps1"),
    (Join-Path $script:moduleDir "InputBridge.ps1"),
    (Join-Path $script:moduleDir "VersionManager.ps1"),
    (Join-Path $script:moduleDir "Update-Manager.ps1"),
    (Join-Path $script:termUIRoot "settings.ini"),
    (Join-Path $script:termUIRoot "buttons")
)

# Self-bootstrap: if modules or core files are missing (e.g., only the EXE was copied),
# download the termUI archive from GitHub and restore the folder structure.
function Restore-TermUIFromGitHub {
    param([string[]]$Missing)
    $esc = [char]27
    Write-Host ("{0}[2J{0}[H" -f $esc) -NoNewline
    Write-Host "Detected missing core files: $($Missing -join ', ')" -ForegroundColor Yellow
    Write-Host "Attempting online repair from GitHub API (termUI folder only)..." -ForegroundColor Yellow
    $repo = "SanitysHelper/cmd"
    $branch = "main"
    $apiUrl = "https://api.github.com/repos/$repo/contents/termUI?ref=$branch"
    $progressPrev = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    try {
        function Download-GitHubDirectory {
            param($Url, $DestPath)
            $headers = @{ 'User-Agent' = 'termUI-Bootstrap' }
            $items = Invoke-RestMethod -Uri $Url -Headers $headers -UseBasicParsing
            foreach ($item in $items) {
                $itemPath = Join-Path $DestPath $item.name
                if ($item.type -eq 'dir') {
                    New-Item -ItemType Directory -Path $itemPath -Force | Out-Null
                    Download-GitHubDirectory -Url $item.url -DestPath $itemPath
                } elseif ($item.type -eq 'file') {
                    Invoke-WebRequest -Uri $item.download_url -OutFile $itemPath -UseBasicParsing
                }
            }
        }
        Download-GitHubDirectory -Url $apiUrl -DestPath $script:termUIRoot
        Write-Host "Repair/download complete. Relaunching..." -ForegroundColor Green
    } catch {
        Write-Host "Bootstrap repair failed: $_" -ForegroundColor Red
        exit 1
    } finally {
        $global:ProgressPreference = $progressPrev
    }
}

# Check and bootstrap before loading modules
$missingCore = @($script:requiredPaths | Where-Object { -not (Test-Path $_) })
if ($missingCore.Count -gt 0) {
    Restore-TermUIFromGitHub -Missing $missingCore
    $script:justBootstrapped = $true
}

# Load version and update managers
. (Join-Path $script:moduleDir "VersionManager.ps1")
. (Join-Path $script:moduleDir "Update-Manager.ps1")

# Check for version/update flags
if ($args -contains "--version" -or $args -contains "-v") {
    Write-Host (Get-TermUIVersionString -TermUIRoot (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
    exit 0
}

if ($args -contains "--changelog" -or $args -contains "-c") {
    Write-Host (Get-TermUIChangelog -TermUIRoot (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
    exit 0
}

if ($args -contains "--check-update") {
    try {
        $null = Start-UpdateCheck -CheckOnly
        exit 0
    } catch { exit 1 }
}

if ($args -contains "--update") {
    $res = Start-UpdateCheck
    if ($res) { exit 0 } else { exit 1 }
}

if ($args -contains "--repair") {
    $res = Start-UpdateCheck -Force
    if ($res) { exit 0 } else { exit 1 }
}

# Optional capture mode for external callers
$captureFile = $null
$capturePath = $null
$captureOnce = $false
$captureAutoIndex = -1
$captureAutoName = $null
$captureTimeoutMs = 0

# Parse capture arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--capture-file" { $captureFile = $args[++$i] }
        "--capture-path" { $capturePath = $args[++$i] }
        "--capture-once" { $captureOnce = $true }
        "--capture-auto-index" { $captureAutoIndex = [int]$args[++$i] }
        "--capture-auto-name" { $captureAutoName = $args[++$i] }
        "--capture-timeout-ms" { $captureTimeoutMs = [int]$args[++$i] }
    }
}

# Track quit requests and handler reference for cleanup
$script:quitRequested = $false
$script:handler = $null
$script:manualInputDetected = $false
$script:isTestEnvironment = $false
$script:justBootstrapped = $false  # Track if we just downloaded from GitHub

$script:paths = @{}
$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:paths.logs = Join-Path $script:scriptDir "..\_bin\_debug\logs" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $script:paths.logs) { $script:paths.logs = Join-Path $script:scriptDir "..\_bin\_debug\logs" }
$script:paths.transcript = Join-Path $script:paths.logs "ui-transcript.log"
$script:paths.settings = Join-Path $script:scriptDir "..\settings.ini"
$script:paths.menuRoot = $null
$script:lastInputTime = Get-Date
$script:inputCounter = 0

# Core files required for a healthy install
$script:requiredPaths = @(
    (Join-Path $script:scriptDir "modules\Logging.ps1"),
    (Join-Path $script:scriptDir "modules\Settings.ps1"),
    (Join-Path $script:scriptDir "modules\MenuBuilder.ps1"),
    (Join-Path $script:scriptDir "modules\InputBridge.ps1"),
    (Join-Path $script:scriptDir "modules\VersionManager.ps1"),
    (Join-Path $script:scriptDir "termUI.ps1"),
    (Join-Path (Split-Path -Parent $script:scriptDir) "settings.ini"),
    (Join-Path (Split-Path -Parent $script:scriptDir) "buttons")
)

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

    # Ensure settings.ini exists or repair first
    if (-not (Test-Path $script:paths.settings)) {
        Write-Host "settings.ini missing; attempting repair from GitHub..." -ForegroundColor Yellow
        $repairResult = Start-UpdateCheck -Force -Silent:$false
        if (-not $repairResult) { Write-Host "Repair failed." -ForegroundColor Red; exit 1 }
    }

    try {
        Initialize-Settings -SettingsPath $script:paths.settings
    } catch {
        Write-Host "Settings load failed; attempting repair from GitHub..." -ForegroundColor Yellow
        $repairResult = Start-UpdateCheck -Force -Silent:$false
        if (-not $repairResult) { Write-Host "Repair failed." -ForegroundColor Red; exit 1 }
        Initialize-Settings -SettingsPath $script:paths.settings
        $script:justBootstrapped = $true
    }

    # Repair if core files are missing
    $missing = @($script:requiredPaths | Where-Object { -not (Test-Path $_) })
    if ($missing.Count -gt 0) {
        Write-Host "Missing required files; attempting repair from GitHub..." -ForegroundColor Yellow
        $repairResult = Start-UpdateCheck -Force -Silent:$false
        if (-not $repairResult) {
            Write-Host "Repair failed. Missing: $($missing -join ', ')" -ForegroundColor Red
            exit 1
        }
        $script:justBootstrapped = $true
    }

    # Optional update check on startup (skip if we just bootstrapped/repaired)
    if ($script:settings.Updates.check_on_startup -and -not $script:justBootstrapped) {
        $updateApplied = Start-UpdateCheck
        if ($updateApplied) {
            Write-Host "Update installed. Please relaunch termUI." -ForegroundColor Yellow
            exit 0
        }
    }

    # CRITICAL: Initialize program-specific buttons before loading menu
    # Each program (tagScanner, etc.) has its own InitializeButtons.ps1 to create dynamic buttons
    # The standalone termUI framework should NEVER have program-specific buttons hardcoded
    # Update-Manager excludes 'buttons' directory to preserve program-specific menus
    $initButtonsScript = Join-Path $script:scriptDir "InitializeButtons.ps1"
    if (Test-Path $initButtonsScript) {
        . $initButtonsScript
    }

    Write-Host "[DEBUG] Loading menu tree..." -ForegroundColor DarkGray
    $script:paths.menuRoot = Join-Path (Join-Path $script:scriptDir "..") $script:settings.General.menu_root
    $script:paths.logLimitBytes = 1024 * 1024 * [int]$script:settings.Logging.log_rotation_mb
    $tree = Build-MenuTree -RootPath $script:paths.menuRoot
    $currentPath = if ($capturePath) { $capturePath } else { "mainUI" }
    $captureStart = Get-Date
    $selectedIndex = 0

    # Check if test environment and initialize handler
    $script:isTestEnvironment = (Test-Path "$script:scriptDir\..\..\automated_testing_environment") -or (Test-Path "$script:scriptDir\..\..\..\automated_testing_environment")
    
    if (($env:TERMUI_TEST_MODE -eq "1") -and $env:TERMUI_TEST_FILE -and (Test-Path $env:TERMUI_TEST_FILE)) {
        # Test mode: load buffered events
        $handlerPath = Join-Path (Join-Path $script:scriptDir "..") $script:settings.Input.handler_path
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        
        # Determine if handler is PS1 or executable
        if ($handlerPath.EndsWith(".ps1")) {
            $psi.FileName = "powershell.exe"
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$handlerPath`" -Replay `"$env:TERMUI_TEST_FILE`""
        } else {
            $psi.FileName = $handlerPath
            $psi.Arguments = "--replay `"$env:TERMUI_TEST_FILE`""
        }
        
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = (New-Object System.Diagnostics.Process)
        $proc.StartInfo = $psi
        $null = $proc.Start()
        
        # Buffer all events
        $eventBuffer = [System.Collections.Generic.Queue[object]]::new()
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line) {
                try {
                    $obj = $line | ConvertFrom-Json
                    $eventBuffer.Enqueue($obj)
                } catch {
                    Log-Error "Failed to parse event: $line"
                }
            }
        }
        $proc.WaitForExit()
        
        $handler = [pscustomobject]@{ Process = $proc; Reader = $null; EventBuffer = $eventBuffer; IsTestMode = $true }
        Log-Important "Started input handler in TEST mode: $env:TERMUI_TEST_FILE (buffered $($eventBuffer.Count) events)"
    } else {
        # Check if input is piped (stdin redirected)
        $isPipedInput = [Console]::IsInputRedirected
        
        if ($isPipedInput) {
            # Piped input mode
            $handler = [pscustomobject]@{ Process = $null; Reader = $null; IsPipedInput = $true }
            Log-Important "Running in piped input mode (stdin redirected)"
        } else {
            # Interactive mode
            $handler = [pscustomobject]@{ Process = $null; Reader = $null; IsInteractive = $true }
            Log-Important "Running in interactive mode (console available)"
        }
    }

    $script:handler = $handler
    $numberBuffer = ""

    function Get-TestInput {
        param([object]$EventBuffer, [object]$Handler)
        
        # In test mode, collect characters until Enter is pressed
        if ($Handler.PSObject.Properties['IsTestMode'] -and $Handler.IsTestMode) {
            $inputBuffer = ""
            while ($EventBuffer.Count -gt 0) {
                $evt = $EventBuffer.Peek()
                if ($evt.key -eq "Enter") {
                    # Consume the Enter event
                    $EventBuffer.Dequeue() | Out-Null
                    return $inputBuffer
                } elseif ($evt.key -eq "Backspace") {
                    $EventBuffer.Dequeue() | Out-Null
                    if ($inputBuffer.Length -gt 0) {
                        $inputBuffer = $inputBuffer.Substring(0, $inputBuffer.Length - 1)
                    }
                } elseif ($evt.key -eq "Char") {
                    $EventBuffer.Dequeue() | Out-Null
                    $inputBuffer += $evt.char
                } else {
                    # Stop collecting if we hit a non-text input key
                    break
                }
            }
            return $inputBuffer
        }
        return $null
    }


    function Render-Menu { 
        param($Items, $Selected, $InputBuffer = "")
        # Use ANSI clear to reduce blue flicker in Windows terminal hosts
        $esc = [char]27
        Write-Host ("{0}[2J{0}[H" -f $esc) -NoNewline
        $versionStr = ""
        try {
            # Try to get version from GitHub first (suppress web progress noise)
            $githubVersionUrl = "https://raw.githubusercontent.com/SanitysHelper/cmd/main/termUI/VERSION.json"
            $prevProgress = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            try {
                $response = Invoke-WebRequest -Uri $githubVersionUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $githubData = $response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($githubData -and $githubData.version) {
                        $versionStr = $githubData.version
                    }
                }
            } catch {
                # GitHub fetch failed, fall back to local version
            } finally {
                $global:ProgressPreference = $prevProgress
            }
            
            # If GitHub fetch failed, use local VERSION.json
            if (-not $versionStr) {
                $vf = Join-Path (Split-Path -Parent $script:scriptDir) "VERSION.json"
                if (Test-Path $vf) {
                    $jsonData = Get-Content $vf -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($jsonData -and $jsonData.version) { 
                        $versionStr = $jsonData.version 
                    }
                }
            }
        } catch {}
        Write-Host "=== $($script:settings.General.ui_title) " -ForegroundColor Cyan -NoNewline
        if ($versionStr) { Write-Host $versionStr -ForegroundColor Blue -NoNewline }
        Write-Host " ===" -ForegroundColor Cyan
        Write-Host "Path: $currentPath" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $color = if ($i -eq $Selected) { "Green" } else { "White" }
            Write-Host "$( if ($i -eq $Selected) { ">" } else { " " } ) [$($i+1)] ($($Items[$i].Type)) $($Items[$i].Name)" -ForegroundColor $color
        }
        Write-Host ""
        if ($Items.Count -gt 0 -and $Selected -ge 0 -and $Selected -lt $Items.Count -and ($Items[$Selected] | Get-Member -Name "Description" -EA SilentlyContinue)) {
            if ($Items[$Selected].Description) {
                Write-Host "Description: $($Items[$Selected].Description)" -ForegroundColor Gray
                Write-Host "" -ForegroundColor Gray
            }
        }
        if ($InputBuffer) {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Backspace] Delete  [Escape] Back  [Q] Quit  |  Input: $InputBuffer" -ForegroundColor Yellow
        } else {
            Write-Host "[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit" -ForegroundColor DarkGray
        }
    }

    # Initialize for smart frame rendering (only render on init and after state changes)
    $firstIteration = $true
    $lastRenderedPath = $null
    
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
        
        # Initialize first iteration flag (only render on init and after state changes)
        # Also render if currentPath changed (menu navigation)
        if (-not (Test-Path variable:firstIteration)) {
            $firstIteration = $true
            $needsRender = $true
        } else {
            # Render if we're on a new path (Enter/Escape changed the current menu)
            $needsRender = ($currentPath -ne $lastRenderedPath)
            $lastRenderedPath = $currentPath
        }
        
        # Render menu on first iteration or after state changes
        if ($firstIteration -or $needsRender) {
            # Rebuild menu tree to reflect any filesystem changes (e.g., new buttons)
            try {
                $tree = Build-MenuTree -RootPath $script:paths.menuRoot
            } catch {
                Log-Error "Failed to rebuild menu tree: $_"
            }
            Log-MenuFrame -Items $items -SelectedIndex $selectedIndex -CurrentPath $currentPath
            Render-Menu -Items $items -Selected $selectedIndex -InputBuffer $numberBuffer
            if ($firstIteration) { $firstIteration = $false }
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
        $needsRender = $false
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
                                
                                # In test mode, get input from event buffer; in interactive mode, use Read-Host
                                if ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode) {
                                    $inputValue = Get-TestInput -EventBuffer $handler.EventBuffer -Handler $handler
                                    if ($null -eq $inputValue) { $inputValue = "" }
                                    Write-Host "$prompt : $inputValue" -ForegroundColor Cyan
                                } else {
                                    $inputValue = Read-Host -Prompt $prompt
                                }
                                
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

                                # Execute the corresponding .ps1 script
                                # Path format is "mainUI/ButtonName", need to get just the relative part after root
                                $pathParts = $item.Path -split '/', 2
                                $relativePath = if ($pathParts.Count -gt 1) { $pathParts[1] } else { $item.Path }
                                $scriptPath = Join-Path $script:paths.menuRoot "$relativePath.ps1"
                                if (Test-Path $scriptPath) {
                                    Log-Important "Executing script: $scriptPath"
                                    try {
                                        & $scriptPath
                                    } catch {
                                        Write-Host "`nERROR executing script: $_" -ForegroundColor Red
                                        Log-Error "Script execution failed: $_"
                                    }
                                } else {
                                    Write-Host "`nScript not found: $scriptPath" -ForegroundColor Yellow
                                    Log-Error "Script not found: $scriptPath"
                                }

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
                        }
                        # Ignore other characters
                    }
                    "Backspace" {
                        # Remove last digit from buffer
                        if ($numberBuffer.Length -gt 0) {
                            $numberBuffer = $numberBuffer.Substring(0, $numberBuffer.Length - 1)
                            $actionTaken = $true
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
                
                # BUG FIX #2 & #5: Log menu frame BEFORE rendering and pass currentPath for better logging
                if ($needsRender) {
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
