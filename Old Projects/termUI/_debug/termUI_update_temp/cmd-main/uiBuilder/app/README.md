# PowerShell UI Menu Builder

**A flexible, programmatic menu system for building hierarchical interactive menus in PowerShell with full piped input support and multi-language code generation.**

## Overview

The PowerShell UI Menu Builder creates hierarchical, interactive command-line menus with the following features:

- **Numbered Menu Selection**: Display options with numeric selection (1, 2, 3...)
- **Interactive Arrow Key Navigation**: Navigate with Up/Down arrows, select with Enter (arrow key mode)
- **Flexible Mode Control**: Switch between numbered and interactive modes via `settings.ini`
- **Hierarchical Navigation**: Organize menus into submenus with breadcrumb navigation
- **Piped Input Support**: Fully automated with no manual typing required - pass all inputs via pipe
- **Multi-Language Integration**: Generate code stubs for PowerShell, Batch, Python, and C#
- **CSV-Based Configuration**: Store menu structure in simple CSV format
- **Exit Code Routing**: Each selection returns a unique exit code for scripting integration
- **File Output**: Selection saved to `run_space/selection.txt` for cross-program communication
- **CLI Command Support**: Add, remove, list, and generate language stubs via command line
- **Configurable Logging**: Enable/disable different log types (navigation, input, error, important)
- **Session Transcript**: Logs all menu screens and user inputs for debugging and auditing

## Quick Start

### Running the Interactive Menu

```powershell
# Launch the menu
.\run.bat

# From pipe (automated)
@("2", "1") -join "`n" | .\run.bat
```

### Using CLI Commands

```powershell
# Add a new menu option
.\run.bat add "My Option" "Description here" "mainUI.myoption" "option"

# List all buttons
.\run.bat list

# Remove a button
.\run.bat remove "mainUI.myoption"

# Generate language stub
.\run.bat --generate-stub ps1   # PowerShell
.\run.bat --generate-stub bat   # Batch
.\run.bat --generate-stub py    # Python
.\run.bat --generate-stub cs    # C#
```

## Menu Modes

The UI Builder supports two menu display modes configured via `settings.ini`:

### Numbered Menu Mode
**Setting**: `default_mode=numbered`

Navigate using numeric input:
```
================================
SELECT OPTION:
================================
1. [Settings]
2. [Tools]

0 = Back
q/Q = Quit

Enter number:
```

- Type the number (1, 2, 3...) and press Enter
- Type `0` to go back, `q` to quit
- Works with both interactive and piped input
- **Best for**: Automation, scripting, batch processing

### Interactive Arrow Key Mode
**Setting**: `default_mode=interactive`

Navigate using arrow keys:
```
================================
SELECT OPTION (use arrow keys):
================================
   1. [Settings]
>> 2. [Tools]

Up/Down = Navigate | Enter = Select | 0/Backspace = Back | Q = Quit
```

- Use **Up/Down** arrows to navigate (highlights with `>>`)
- Press **Enter** to select highlighted option
- Press **0** or **Backspace** to go back, **Q** to quit
- Falls back to numbered input automatically when piped
- **Best for**: Interactive user sessions

**Automatic Mode Fallback**: When input is piped (for automation), interactive mode automatically falls back to numbered mode to ensure compatibility.

## Menu Structure

The menu structure is stored in `button.list` (CSV format):

```csv
Name,Description,Path,Type
Settings,Configure application settings,mainUI.settings,submenu
Edit Settings,Modify settings.ini,mainUI.settings.edit,option
View Logs,Display application logs,mainUI.settings.viewlogs,option
Tools,System utilities,mainUI.tools,submenu
Run Tests,Execute test suite,mainUI.tools.tests,option
```

### CSV Fields

- **Name**: Display name shown in menu
- **Description**: Short description (optional)
- **Path**: Hierarchical path with dots (e.g., `mainUI.settings.edit`)
- **Type**: Either `submenu` or `option`
  - `submenu`: Has child items, selecting navigates deeper
  - `option`: Leaf item, selecting outputs and exits

### Path Naming Convention

- Use lowercase alphanumeric + underscores
- Use dots to create hierarchy
- Root level: `mainUI`
- Submenus: `mainUI.category`
- Options: `mainUI.category.action`
- Example: `mainUI.settings.edit` = Edit option under Settings

## Interactive Menu Usage

When you run the menu interactively, you'll see:

```
================================
SELECT OPTION:
================================
1. [Settings]
2. [Tools]

0 = Back
q/Q = Quit

Enter number:
```

### Navigation Keys

- **1-9**: Select numbered option
- **0**: Go back to parent menu
- **q**: Quit and exit with code 99
- **Enter**: Confirm selection

## Output Methods

When a user selects an option, the program outputs in three ways:

### 1. Exit Code
The exit code equals the menu item number (1, 2, 3, etc.)

```powershell
$output = & .\run.bat
$exitCode = $LASTEXITCODE  # 1 = first item, 2 = second item, etc.
```

### 2. Console Output
Displays confirmation message:
```
Selected: mainUI.tools.tests
```

### 3. File Output
Writes selection path to `run_space/selection.txt`:
```
mainUI.tools.tests
```

## Integration Example

### PowerShell Integration

```powershell
# Launch menu and capture result
$selectionFile = ".\run_space\selection.txt"
& .\run.bat
$selection = Get-Content $selectionFile

# Act based on selection
switch ($selection) {
    "mainUI.settings.edit" { Edit-Settings }
    "mainUI.tools.tests" { Invoke-TestRunner }
}
```

Or use the generated stub:

```powershell
.\run.bat --generate-stub ps1 | Out-File MyIntegration.ps1
```

### Batch Integration

```batch
@echo off
call run.bat
set /p selection=<run_space\selection.txt

if "%selection%"=="mainUI.settings.edit" (
    call :EditSettings
) else if "%selection%"=="mainUI.tools.tests" (
    call :RunTests
)
exit /b 0
```

### Python Integration

```python
import subprocess
import os

# Launch menu
result = subprocess.run(['powershell', '-File', 'UI-Builder.ps1'])

# Read selection
with open('run_space/selection.txt', 'r') as f:
    selection = f.read().strip()

if selection == "mainUI.tools.python":
    print("Running Python integration!")
```

## Configuration

### settings.ini

The `settings.ini` file controls behavior:

```ini
[General]
default_mode=numbered
enable_colors=true
auto_generate_stubs=false
remember_last_path=false

[Colors]
highlight_color=Green
shift_color=Yellow
arrow_color=Cyan
error_color=Red

[Logging]
log_input=true
log_important=true
log_error=true
log_output=true
log_terminal=false
log_debug=false
log_function_calls=false
log_performance=false
```

### Logging

Logs are written to `_debug/logs/` directory:

- `navigation.log` - Menu navigation events
- `input.log` - User inputs and commands
- `important.log` - Critical state changes
- `error.log` - Errors and exceptions
- `ui-debug.log` - Detailed UI state (debug mode only)

Control logging via `settings.ini` [Logging] section.

## Automated Testing

The included test suite validates all functionality:

```powershell
cd _debug/automated_testing_environment
& .\run_tests_fixed.ps1
```

Tests cover:
- Interactive menu navigation
- Submenu transitions
- Back/quit functionality
- CLI add/remove operations
- Language stub generation
- Exit code correctness
- File output validation

All tests use piped input - no manual typing required.

## Piped Input (Automation)

For non-interactive use, pipe multiple inputs separated by newlines:

```powershell
# Navigate: Select Tools (2), then Run Tests (1)
@("2", "1") -join "`n" | .\run.bat

# Quit immediately
"q" | .\run.bat

# Navigate back: Select item (2), go back (0), quit (q)
@("2", "0", "q") -join "`n" | .\run.bat
```

The menu will:
1. Show first menu
2. Read first input ("2")
3. Navigate to submenu
4. Show submenu
5. Read second input ("1")
6. Execute selection

This enables full automation without any manual terminal input.

## Architecture

### File Structure

```
uiBuilder/
├── run.bat                      # Batch launcher
├── UI-Builder.ps1               # Main PowerShell script (~770 lines)
├── button.list                  # CSV menu definitions
├── settings.ini                 # Configuration
├── run_space/                   # Execution temp directory
│   └── selection.txt            # Output selection path
└── _debug/
    ├── logs/                    # Log files directory
    ├── backups/                 # Version backups
    └── automated_testing_environment/
        ├── run.bat              # Copy for testing
        ├── UI-Builder.ps1       # Copy for testing
        ├── button.list          # Copy for testing
        ├── settings.ini         # Copy for testing
        ├── run_tests_fixed.ps1  # Test harness
        └── run_space/           # Test temp directory
```

### Core Functions

**Data Management:**
- `Read-ButtonList` - Parse CSV to objects
- `Write-ButtonList` - Serialize objects to CSV
- `Get-ChildButtons` - Filter by parent path
- `Add-ButtonOption` - Insert and persist new button
- `Remove-ButtonOption` - Delete and persist button removal

**Display:**
- `Show-NumberedMenu` - Display options, capture input
- `Show-DescriptionBox` - Show detailed description

**Output:**
- `Invoke-OutputSelection` - Write file, console, exit code

**Logging:**
- `Log-Navigation`, `Log-Input`, `Log-Error`, `Log-Important`

**CLI:**
- `Invoke-AddButton` - CLI add handler
- `Invoke-RemoveButton` - CLI remove handler
- `Invoke-ListButtons` - CLI list handler
- `Get-LanguageStub` - Generate code stub

**Main Loop:**
- `Invoke-MainLoop` - Interactive menu loop with navigation

### Design Principles

1. **Separation of Concerns**: UI logic separate from business logic
2. **Pure Functions**: No side effects except logging and I/O
3. **Data-Driven**: Menu structure from CSV, not hardcoded
4. **Piped Input**: Full automation support from day one
5. **Error Handling**: Comprehensive try-catch with logging
6. **Exit Codes**: Predictable routing for script integration

## Language Stubs

Generate integration code for any language:

### PowerShell Stub
```powershell
$selectionFile = ".\run_space\selection.txt"
$selection = Get-Content -Path $selectionFile -ErrorAction Stop

Write-Host "You selected: $selection"

switch ($selection) {
    "mainUI.settings.edit" { Edit-Settings }
    "mainUI.tools.python" { Invoke-PythonRunner }
    default { Write-Host "Unknown selection: $selection" }
}
```

### Batch Stub
```batch
@echo off
setlocal enabledelayedexpansion
for /f "delims=" %%a in (run_space\selection.txt) do (
    set "selection=%%a"
)
echo You selected: !selection!

if "!selection!"=="mainUI.settings.edit" (
    call :EditSettings
) else if "!selection!"=="mainUI.tools.python" (
    call :InvokePythonRunner
)
exit /b 0
```

### Python Stub
```python
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

if selection == "mainUI.settings.edit":
    print("Running Edit Settings...")
elif selection == "mainUI.tools.python":
    print("Running Python Runner...")
```

### C# Stub
```csharp
using System;
using System.IO;

class Program {
    static void Main() {
        string selectionFile = "run_space/selection.txt";
        string selection = File.ReadAllText(selectionFile).Trim();
        
        Console.WriteLine($"You selected: {selection}");
        
        switch(selection) {
            case "mainUI.settings.edit":
                EditSettings();
                break;
            case "mainUI.tools.python":
                InvokePythonRunner();
                break;
        }
    }
}
```

## Troubleshooting

### Menu not showing / No output
**Issue**: Script runs silently or hangs.
**Cause**: PowerShell execution policy restricted.
**Solution**: 
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

### Piped input not working
**Issue**: When piping input, menu exits with code 99 (quit) instead of processing selection.
**Cause**: Old version using Read-Host which doesn't consume piped input.
**Solution**: Update to latest version which uses `[Console]::IsInputRedirected` check + `[Console]::In.ReadLine()`.

### Selection file not created
**Issue**: `run_space/selection.txt` is empty or missing after selection.
**Cause**: Selected a submenu instead of an option, or exit code routing incorrectly.
**Solution**: Verify you selected an option (marked with `*`), not a submenu (marked with `[]`).

### Log files not created
**Issue**: `_debug/logs/` directory exists but no log files.
**Cause**: Logging disabled in settings.ini.
**Solution**: Set `log_input=true`, `log_important=true`, etc. in `[Logging]` section.

## Advanced Usage

### Programmatic Menu Creation

Add buttons via CLI instead of editing CSV:

```powershell
.\run.bat add "Database" "Database operations" "mainUI.db" "submenu"
.\run.bat add "Query" "Run query" "mainUI.db.query" "option"
.\run.bat add "Backup" "Backup database" "mainUI.db.backup" "option"
.\run.bat list
```

### Reading Logs

Check navigation history:
```powershell
Get-Content _debug/logs/navigation.log
```

View recent errors:
```powershell
Get-Content _debug/logs/error.log | Select-Object -Last 20
```

### Debug Mode

Enable detailed logging:
```powershell
.\run.bat --debug
```

This enables:
- Full UI state logging (menu items, paths, indices)
- Detailed input logging (before/after processing)
- Function-level tracing

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | CLI command successful (add/remove/list/stub) |
| 1-N | Menu option selected (N = option number) |
| 99 | User quit (q key) |
| 1 | Error occurred |

## Performance Notes

- **CSV Parsing**: Loaded once at startup into memory hashtable
- **Menu Display**: ~10ms per render
- **Piped Input**: Single read per prompt, no buffering overhead
- **File I/O**: Async logging, doesn't block menu
- **Memory**: ~2-5MB depending on menu size

## Requirements

- PowerShell 5.0 or later
- Windows 7 SP1 or later
- No external dependencies (uses only built-in cmdlets)
- Batch files optional (for launching from cmd.exe)

## License

This tool is provided as-is for automation and scripting scenarios.

## Version History

- **v1.0** (2024-12-06): Initial release
  - Numbered menu interface
  - Piped input support
  - CSV-based menu structure
  - CLI commands (add/remove/list)
  - Language stub generation (PS1, BAT, PY, C#)
  - Hierarchical submenu navigation
  - Configurable logging
  - Exit code routing

---

*For integration examples and advanced usage, see the `_debug/automated_testing_environment/run_tests_fixed.ps1` test harness which demonstrates all features.*

