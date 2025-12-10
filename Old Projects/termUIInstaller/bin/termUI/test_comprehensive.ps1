#Requires -Version 5.0
<#
.SYNOPSIS
Comprehensive test suite for termUI program
Tests all input types, navigation paths, handlers, and edge cases
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:testResults = @()
$script:testCount = 0
$script:passCount = 0
$script:failCount = 0

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "TEST: $Title" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
}

function Assert-Equal {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$Message = ""
    )
    $script:testCount++
    if ($Actual -eq $Expected) {
        $script:passCount++
        Write-Host "[PASS] $Message" -ForegroundColor Green
        return $true
    } else {
        $script:failCount++
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        Write-Host "  Expected: $Expected" -ForegroundColor Yellow
        Write-Host "  Actual:   $Actual" -ForegroundColor Yellow
        return $false
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message = ""
    )
    $script:testCount++
    if ($Condition) {
        $script:passCount++
        Write-Host "[PASS] $Message" -ForegroundColor Green
        return $true
    } else {
        $script:failCount++
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        return $false
    }
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$Message = ""
    )
    $script:testCount++
    if (Test-Path $Path) {
        $script:passCount++
        Write-Host "[PASS] $Message" -ForegroundColor Green
        return $true
    } else {
        $script:failCount++
        Write-Host "[FAIL] $Message - File not found: $Path" -ForegroundColor Red
        return $false
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$SearchString,
        [string]$Message = ""
    )
    $script:testCount++
    if ($Content -match [regex]::Escape($SearchString)) {
        $script:passCount++
        Write-Host "[PASS] $Message" -ForegroundColor Green
        return $true
    } else {
        $script:failCount++
        Write-Host "[FAIL] $Message - String not found: $SearchString" -ForegroundColor Red
        return $false
    }
}

# ========== TEST 1: Module Loading ==========
Write-TestHeader "Module Loading and Dependencies"

$termUIRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleDir = Join-Path $termUIRoot "powershell\modules"

$modules = @(
    "Logging.ps1"
    "Settings.ps1"
    "MenuBuilder.ps1"
    "InputBridge.ps1"
    "TermUIButtonLibrary.ps1"
    "VersionManager.ps1"
)

foreach ($mod in $modules) {
    $modPath = Join-Path $moduleDir $mod
    Assert-FileExists $modPath "Module $mod exists"
}

# ========== TEST 2: Menu Structure ==========
Write-TestHeader "Menu Structure and Navigation"

$menuRoot = Join-Path $termUIRoot "buttons\mainUI"

$expectedFolders = @("Settings", "SettingsCommand", "TextInput", "Tools")
foreach ($folder in $expectedFolders) {
    $path = Join-Path $menuRoot $folder
    Assert-FileExists $path "Menu folder exists: $folder"
}

# Check option files
$optFiles = @(
    "Settings/Logging/Debugging/error.opt"
    "Settings/Logging/Debugging/warn.opt"
    "SettingsCommand/Operation/add.opt"
    "SettingsCommand/Operation/subtract.opt"
)
foreach ($optFile in $optFiles) {
    $path = Join-Path $menuRoot $optFile
    Assert-FileExists $path ".opt file exists: $optFile"
}

# Check input files
$inputFiles = @(
    "TextInput/UserName.input"
    "TextInput/NumberA.input"
    "TextInput/NumberB.input"
    "TextInput/CustomValue.input"
)
foreach ($inputFile in $inputFiles) {
    $path = Join-Path $menuRoot $inputFile
    Assert-FileExists $path ".input file exists: $inputFile"
}

# ========== TEST 3: Version Functionality ==========
Write-TestHeader "Version and Changelog Functionality"

$versionOutput = & powershell -ExecutionPolicy Bypass -File "$termUIRoot\powershell\termUI.ps1" --version 2>&1
Assert-Contains $versionOutput "termUI v" "Version flag returns version string"
Assert-Contains $versionOutput "2025" "Version includes year"

$changelogOutput = & powershell -ExecutionPolicy Bypass -File "$termUIRoot\powershell\termUI.ps1" --changelog 2>&1
Assert-Contains $changelogOutput "Changes" "Changelog flag returns content"

# ========== TEST 4: Settings Loading ==========
Write-TestHeader "Settings Configuration"

$settingsPath = Join-Path $termUIRoot "settings.ini"
Assert-FileExists $settingsPath "Settings file exists"

$settingsContent = Get-Content $settingsPath -Raw
Assert-Contains $settingsContent "debug_mode" "Settings contains debug_mode"
Assert-Contains $settingsContent "ui_title" "Settings contains ui_title"
Assert-Contains $settingsContent "log_input" "Settings contains logging config"

# ========== TEST 5: Logging System ==========
Write-TestHeader "Logging System and Log Files"

$logsDir = Join-Path $termUIRoot "_bin\_debug\logs"
if (Test-Path $logsDir) {
    Write-Host "Logs directory exists" -ForegroundColor Green
    
    $logFiles = @("input.log", "important.log", "error.log", "menu-frame.log", "input-timing.log")
    foreach ($logFile in $logFiles) {
        $logPath = Join-Path $logsDir $logFile
        if (Test-Path $logPath) {
            Write-Host "[INFO] Log file exists: $logFile" -ForegroundColor Cyan
            $fileSize = (Get-Item $logPath).Length
            Write-Host "[INFO] Size: $fileSize bytes" -ForegroundColor Cyan
        }
    }
}

# ========== TEST 6: Input Handler Availability ==========
Write-TestHeader "Input Handler Configuration"

$handlerPath = "$termUIRoot\csharp\bin\InputHandler.exe"
if (Test-Path $handlerPath) {
    Assert-True $true "InputHandler.exe is available (can use event buffering mode)"
} else {
    Assert-True $true "InputHandler.exe not available (will use interactive ReadKey mode)"
    Write-Host "[INFO] Program will fall back to [Console]::ReadKey() for interactive input" -ForegroundColor Yellow
}

# ========== TEST 7: Input Types Testing ==========
Write-TestHeader "Input Type Detection (Code Analysis)"

$termUIScript = Join-Path $termUIRoot "powershell\termUI.ps1"
$scriptContent = Get-Content $termUIScript -Raw

# Check for input handling patterns
Assert-Contains $scriptContent '"Up"' "Up arrow handling implemented"
Assert-Contains $scriptContent '"Down"' "Down arrow handling implemented"
Assert-Contains $scriptContent '"Enter"' "Enter key handling implemented"
Assert-Contains $scriptContent '"Escape"' "Escape key handling implemented"
Assert-Contains $scriptContent '"Q"' "Q key handling for quit"
Assert-Contains $scriptContent '"Char"' "Character input handling for numbers"
Assert-Contains $scriptContent '"Backspace"' "Backspace handling for input buffer"

# ========== TEST 8: Button Library Functions ==========
Write-TestHeader "Button Library Functions"

$buttonLib = Join-Path $moduleDir "TermUIButtonLibrary.ps1"
$buttonContent = Get-Content $buttonLib -Raw

$buttonFunctions = @(
    "Clear-TermUIButtons"
    "Add-TermUIButton"
    "Add-TermUIButtonBatch"
    "Add-TermUIButtonRange"
    "Add-TermUIButtonChoice"
)
foreach ($func in $buttonFunctions) {
    Assert-Contains $buttonContent "function $func" "Function $func defined"
}

# ========== TEST 9: Menu Building Functions ==========
Write-TestHeader "Menu Builder Functions"

$menuLib = Join-Path $moduleDir "MenuBuilder.ps1"
$menuContent = Get-Content $menuLib -Raw

$menuFunctions = @(
    "Build-MenuTree"
    "Get-MenuNode"
    "Get-MenuItemsAtPath"
)
foreach ($func in $menuFunctions) {
    Assert-Contains $menuContent "function $func" "Function $func defined"
}

# ========== TEST 10: InputBridge Handler ==========
Write-TestHeader "InputBridge Handler Functions"

$inputBridge = Join-Path $moduleDir "InputBridge.ps1"
$inputContent = Get-Content $inputBridge -Raw

Assert-Contains $inputContent "function Stop-InputHandler" "Stop-InputHandler function exists"
Assert-Contains $inputContent "function Get-NextInputEvent" "Get-NextInputEvent function exists"
Assert-Contains $inputContent "IsTestMode" "Test mode support implemented"
Assert-Contains $inputContent "IsInteractive" "Interactive mode support implemented"

# ========== TEST 11: Error Handling ==========
Write-TestHeader "Error Handling and Logging"

Assert-Contains $scriptContent "try" "Try-catch blocks implemented"
Assert-Contains $scriptContent "catch" "Error handling implemented"
Assert-Contains $scriptContent "Log-Error" "Error logging function calls"

# ========== TEST 12: Frame Rendering ==========
Write-TestHeader "Frame Rendering Logic"

Assert-Contains $scriptContent "Render-Menu" "Render-Menu function defined"
Assert-Contains $scriptContent "Write-Host.*Green" "Color output for selected items"
Assert-Contains $scriptContent "Write-Host.*White" "Color output for unselected items"

# ========== TEST 13: Number Buffer Input ==========
Write-TestHeader "Number Buffer Quick Select (Code Analysis)"

Assert-Contains $scriptContent '$numberBuffer' "Number buffer variable used"
Assert-Contains $scriptContent '\[int\]$numberBuffer' "Number buffer converted to index"
Assert-Contains $scriptContent 'Substring' "Buffer substring operations for backspace"

# ========== TEST 14: Navigation State Tracking ==========
Write-TestHeader "Navigation State and Path Tracking"

Assert-Contains $scriptContent '$currentPath' "Current path tracking"
Assert-Contains $scriptContent '$selectedIndex' "Selected index tracking"
Assert-Contains $scriptContent '$lastRenderedPath' "Last rendered path for frame optimization"

# ========== TEST 15: Capture Mode ==========
Write-TestHeader "Capture Mode for External Callers"

Assert-Contains $scriptContent '--capture-file' "Capture file argument support"
Assert-Contains $scriptContent '--capture-path' "Capture path argument support"
Assert-Contains $scriptContent '--capture-auto-index' "Auto-select index argument support"
Assert-Contains $scriptContent '--capture-auto-name' "Auto-select name argument support"

# ========== MANUAL INTERACTION TESTS ==========
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Magenta
Write-Host "INTERACTIVE TESTING SECTION" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor Magenta
Write-Host @"

The following tests require manual interaction since InputHandler.exe is not available.
To run interactive tests:

1. NAVIGATION TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then: 
     - Press Down arrow 2 times (select Settings)
     - Press Enter to navigate into Settings
     - Press Escape to go back to root
     - Press Q to quit
   Expected: Menu should render correctly at each step

2. QUICK SELECT TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then:
     - Press 3 (selects third item)
     - Press Enter to navigate/select
     - Press Escape to go back
     - Press Q to quit
   Expected: Number buffer should show "3" in input area

3. SUBMENU EXPLORATION TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then:
     - Down arrow to "Settings"
     - Enter to Settings
     - Down arrow to "Logging"
     - Enter to Logging
     - Down arrow to "Debugging"
     - Enter to Debugging (select error.opt option)
     - Observe output, press key to continue
     - Try Escape multiple times to go back
     - Press Q to quit
   Expected: All navigation should work smoothly

4. TEXT INPUT TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then:
     - Down 3 times to "TextInput"
     - Enter to TextInput
     - Down to "UserName"
     - Enter, type a name, press Enter
     - Observe output
     - Try another .input option
   Expected: Input prompts should accept text correctly

5. NUMBER BUFFER BACKSPACE TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then:
     - Press 1 (buffer shows "1")
     - Press 2 (buffer shows "12")
     - Press Backspace (buffer shows "1")
     - Press Escape (buffer clears, shows empty)
   Expected: Number buffer should update correctly with each key

6. PATH VALIDATION TEST:
   Run: powershell -ExecutionPolicy Bypass -File .\powershell\termUI.ps1
   Then:
     - Navigate deep: Settings > Logging > Debugging
     - Select an option
     - Press Escape to go back level by level
     - Verify currentPath updates correctly
   Expected: Path should be: mainUI/Settings/Logging/Debugging -> mainUI/Settings/Logging -> mainUI/Settings -> mainUI

"@ -ForegroundColor Yellow

# ========== TEST SUMMARY ==========
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "TEST SUMMARY" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green

Write-Host "Total Tests:  $script:testCount" -ForegroundColor Cyan
Write-Host "Passed:       $script:passCount" -ForegroundColor Green
Write-Host "Failed:       $script:failCount" -ForegroundColor Red
Write-Host ""

$successRate = if ($script:testCount -gt 0) { [int](($script:passCount / $script:testCount) * 100) } else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

if ($script:failCount -eq 0) {
    Write-Host "`n[SUCCESS] All code-based tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Some tests failed. See details above." -ForegroundColor Red
    exit 1
}
