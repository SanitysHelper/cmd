# ============================================================================
# COMMAND HANDLERS MODULE
# ============================================================================
# CLI commands and main loop logic

function Invoke-OutputSelection {
    param(
        [string]$SelectedPath,
        [int]$ExitCode,
        [string]$OutputDir = $script:runSpacePath
    )
    
    # Write to file
    $selectionFile = Join-Path $OutputDir "selection.txt"
    Set-Content -Path $selectionFile -Value $SelectedPath -Encoding UTF8
    
    # Output to console
    Write-Host "Selected: $SelectedPath"
    
    # Exit with code
    exit $ExitCode
}

function Invoke-MainLoop {
    while ($true) {
        Log-Debug "Current path: $script:currentPath, Breadcrumb: $($script:breadcrumb -join ' > ')"
        
        # Get child buttons for current path
        $currentItems = @(Get-ChildButtons -ParentPath $script:currentPath)
        
        if ($currentItems.Count -eq 0) {
            Write-Host "No items in this menu" -ForegroundColor Red
            Log-Error "No items found for path: $script:currentPath"
            exit 1
        }
        
        # Show menu based on default_mode setting
        $mode = $script:settings.General['default_mode']
        if ($mode -eq 'interactive') {
            $result = Show-InteractiveMenu -Items $currentItems `
                -HighlightColor $script:settings.Colors['highlight_color'] `
                -ArrowColor $script:settings.Colors['arrow_color'] `
                -ShiftColor $script:settings.Colors['shift_color']
        } else {
            $result = Show-NumberedMenu -Items $currentItems `
                -HighlightColor $script:settings.Colors['highlight_color'] `
                -ShiftColor $script:settings.Colors['shift_color']
        }
        
        if ($result.Action -eq 'quit') {
            Log-Important "User quit"
            exit 99
        }
        
        if ($result.Action -eq 'back') {
            if ($script:breadcrumb.Count -gt 1) {
                $script:breadcrumb = $script:breadcrumb[0..($script:breadcrumb.Count - 2)]
                $script:currentPath = $script:breadcrumb[-1]
                Log-Navigation "Navigated back to: $script:currentPath"
            }
            continue
        }
        
        if ($result.Action -eq 'select') {
            if ($result.Index -lt 0 -or $null -eq $currentItems -or $result.Index -ge $currentItems.Count) {
                Log-Error "Invalid index: $($result.Index), items count: $($currentItems.Count)"
                Write-Host "Invalid index. Please try again." -ForegroundColor Red
                continue
            }
            
            $selectedItem = $currentItems[$result.Index]
            
            if ($selectedItem['Type'] -eq 'submenu') {
                # Navigate to submenu
                $script:currentPath = $selectedItem['Path']
                $script:breadcrumb += $selectedItem['Path']
                Log-Navigation "Opened submenu: $($selectedItem['Path'])"
            } else {
                # Option selected - output and exit
                $selectedIndex = $result.Index + 1
                Log-Important "Selected option: $($selectedItem['Name']) (path: $($selectedItem['Path']))"
                Invoke-OutputSelection -SelectedPath $selectedItem['Path'] -ExitCode $selectedIndex
            }
        }
    }
}

function Invoke-AddButton {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Path,
        [string]$Type
    )
    
    if (Add-ButtonOption -Name $Name -Description $Description -Path $Path -Type $Type) {
        Write-Host "Button added successfully: $Path" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Failed to add button" -ForegroundColor Red
        return 1
    }
}

function Invoke-RemoveButton {
    param([string]$Path)
    
    if (Remove-ButtonOption -Path $Path) {
        Write-Host "Button removed successfully: $Path" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Failed to remove button" -ForegroundColor Red
        return 1
    }
}

function Invoke-ListButtons {
    $buttons = @($script:buttonIndex.Values) | Sort-Object Path
    
    if ($buttons.Count -eq 0) {
        Write-Host "No buttons found"
        return
    }
    
    Write-Host "Button List:" -ForegroundColor Green
    Write-Host "============"
    foreach ($button in $buttons) {
        $type = if ($button.Type -eq 'submenu') { '[S]' } else { '[O]' }
        Write-Host "$($type) $($button.Path): $($button.Name)"
    }
}

function Get-LanguageStub {
    param([string]$Language)
    
    $stubs = @{
        ps1 = @'
# PowerShell stub: Read selection from uiBuilder

$selectionFile = ".\run_space\selection.txt"
$selection = Get-Content -Path $selectionFile -ErrorAction Stop

Write-Host "You selected: $selection"

# Call your function here based on selection
switch ($selection) {
    "mainUI.settings.edit" { Edit-Settings }
    "mainUI.tools.python" { Invoke-PythonRunner }
    default { Write-Host "Unknown selection: $selection" }
}
'@
        bat = @'
REM Batch stub: Read selection from uiBuilder

@echo off
setlocal enabledelayedexpansion

set "selectionFile=run_space\selection.txt"

if not exist %selectionFile% (
    echo Selection file not found
    exit /b 1
)

for /f "usebackq delims=" %%a in ("%selectionFile%") do (
    set "selection=%%a"
)

echo You selected: !selection!

REM Call your function here based on selection
if "!selection!"=="mainUI.settings.edit" (
    call :EditSettings
) else if "!selection!"=="mainUI.tools.python" (
    call :InvokePythonRunner
)

exit /b 0

:EditSettings
    echo Running Edit Settings...
    exit /b 0

:InvokePythonRunner
    echo Running Python Runner...
    exit /b 0
'@
        py = @'
# Python stub: Read selection from uiBuilder

import sys
import os

selection_file = "run_space/selection.txt"

try:
    with open(selection_file, 'r') as f:
        selection = f.read().strip()
except FileNotFoundError:
    print("Selection file not found")
    sys.exit(1)

print(f"You selected: {selection}")

# Call your function here based on selection
if selection == "mainUI.settings.edit":
    print("Running Edit Settings...")
elif selection == "mainUI.tools.python":
    print("Running Python Runner...")
else:
    print(f"Unknown selection: {selection}")
'@
        cs = @'
// C# stub: Read selection from uiBuilder

using System;
using System.IO;

class Program {
    static int Main(string[] args) {
        string selectionFile = "run_space/selection.txt";
        
        if (!File.Exists(selectionFile)) {
            Console.WriteLine("Selection file not found");
            return 1;
        }
        
        string selection = File.ReadAllText(selectionFile).Trim();
        
        Console.WriteLine($"You selected: {selection}");
        
        // Call your function here based on selection
        switch (selection) {
            case "mainUI.settings.edit":
                EditSettings();
                break;
            case "mainUI.tools.python":
                InvokePythonRunner();
                break;
            default:
                Console.WriteLine($"Unknown selection: {selection}");
                break;
        }
        
        return 0;
    }
    
    static void EditSettings() {
        Console.WriteLine("Running Edit Settings...");
    }
    
    static void InvokePythonRunner() {
        Console.WriteLine("Running Python Runner...");
    }
}
'@
    }
    
    if ($stubs.ContainsKey($Language)) {
        return $stubs[$Language]
    } else {
        Write-Host "Language not supported: $Language" -ForegroundColor Red
        return $null
    }
}
