# Settings Manager - Modular Architecture

## Overview
Settings Manager has been refactored into a modular architecture with a C# GUI frontend calling PowerShell modules for business logic.

## Structure
```
settings/
├── Settings-Manager.exe      # C# GUI executable (compiled from modules/csharp/)
├── Settings-Manager.ps1      # PowerShell orchestrator (loads modules)
├── run.bat                   # Legacy launcher (optional, for CLI mode)
├── compile.bat               # Compiles C# source to .exe
├── modules/
│   ├── powershell/           # Business logic modules
│   │   ├── Logging.ps1       # Write-Log, Write-OperationLog
│   │   ├── SettingsIO.ps1    # Load-Settings, Save-Settings
│   │   ├── FileWatcher.ps1   # File change monitoring
│   │   ├── InputHandler.ps1  # Get-UserInput, Test-Timeout
│   │   └── Cleanup.ps1       # Invoke-Cleanup
│   ├── config/               # Configuration files
│   │   ├── settings.ini      # User settings
│   │   ├── .internal_config  # Internal configuration
│   │   └── README.md         # User documentation
│   └── csharp/               # GUI source code
│       └── SettingsManagerGUI.cs  # Windows Forms application
├── _runspace/                # Temporary execution artifacts
└── _debug/
    ├── logs/                 # All log files
    │   ├── important.log
    │   ├── input.log
    │   ├── error.log
    │   └── ...
    └── automated_testing_environment/

```

## Modules

### PowerShell Modules (modules/powershell/)

**Logging.ps1** (36 lines)
- `Write-Log`: Timestamp logging with conditional enable/disable
- `Write-OperationLog`: Structured logging (OPERATION|INPUT|OUTPUT|CONTEXT|STATUS|DETAILS)

**SettingsIO.ps1** (134 lines)
- `Load-Settings`: Parses INI file into nested hashtable (Section → Key → {Value, Description})
- `Save-Settings`: Writes formatted INI with verification and timestamp tracking

**FileWatcher.ps1** (80 lines)
- `Initialize-FileWatcher`: Creates System.IO.FileSystemWatcher for settings.ini
- `Test-SettingsFileChanged`: Detects external file modifications
- `Update-LastModifiedTime`: Prevents false positives after internal saves
- `Stop-FileWatcher`: Cleanup and disposal

**InputHandler.ps1** (52 lines)
- `Get-UserInput`: Safe Read-Host with null handling, password masking, logging
- `Test-Timeout`: Execution timeout enforcement

**Cleanup.ps1** (40 lines)
- `Invoke-Cleanup`: Creates _runspace/, cleans *.tmp files, disposes resources

### C# GUI (Settings-Manager.exe)

**Features**:
- Windows Forms application with DataGridView for settings display
- Button menu: View All, Edit, Add, Reload, Save, Debug, Quit
- Log panel at bottom: Tracks all clicks, keypresses, operations
- Calls PowerShell modules via Settings-Manager.ps1 orchestrator

**Controls**:
- **DataGridView**: Displays settings in Section | Key | Value | Description format
- **Buttons**: Menu actions
- **RichTextBox**: Scrolling log console (black background, green text)

**Interaction Logging**:
- All button clicks logged with timestamp
- Cell edits logged
- Form events logged
- PowerShell operation results logged

## Compilation

### Requirements
- .NET Framework 4.0+ (for C# compiler)
- PowerShell 5.1+ (for modules)
- Windows Forms (included in .NET Framework)

### Compile Command
```batch
compile.bat
```

This will:
1. Locate C# compiler (csc.exe)
2. Reference required assemblies (System.Management.Automation.dll, System.Windows.Forms.dll, etc.)
3. Compile modules/csharp/SettingsManagerGUI.cs to Settings-Manager.exe
4. Display compilation result

### Manual Compilation
```batch
%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe ^
  /target:winexe ^
  /out:Settings-Manager.exe ^
  /r:System.Management.Automation.dll ^
  /r:System.Windows.Forms.dll ^
  /r:System.Drawing.dll ^
  /r:Microsoft.VisualBasic.dll ^
  modules\csharp\SettingsManagerGUI.cs
```

## Usage

### GUI Mode (Primary)
Double-click `Settings-Manager.exe`

### CLI Mode (Legacy)
```batch
run.bat
```

## Module Loading Pattern

Settings-Manager.ps1 uses **explicit module loading** (most secure):

```powershell
$modulesToLoad = @(
    'Logging.ps1'
    'SettingsIO.ps1'
    'FileWatcher.ps1'
    'InputHandler.ps1'
    'Cleanup.ps1'
)

foreach ($module in $modulesToLoad) {
    $modulePath = Join-Path $PSModulesDir $module
    if (Test-Path $modulePath) {
        . $modulePath  # Dot-source to load functions
    }
}
```

C# GUI calls operations via:
```csharp
PowerShell ps = PowerShell.Create();
ps.Runspace = runspace;
ps.AddCommand(scriptPath);
ps.AddParameter("Operation", "LoadSettings");
var results = ps.Invoke();
```

## Operations

Settings-Manager.ps1 supports these operations (called by C# GUI):

- **LoadSettings**: Returns hashtable of all settings
- **SaveSettings**: Writes hashtable to settings.ini
- **InitializeWatcher**: Starts file system monitoring
- **CheckFileChanged**: Tests if settings.ini was modified externally
- **UpdateModifiedTime**: Updates timestamp after internal save
- **Cleanup**: Cleanup resources on exit

## Testing

### Automated Testing
```powershell
cd _debug\automated_testing_environment
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item ..\..\Settings-Manager.exe .
Copy-Item ..\..\Settings-Manager.ps1 .
Copy-Item -Recurse ..\..\modules .
.\Settings-Manager.exe
```

### Module Testing
Test individual modules:
```powershell
Import-Module .\modules\powershell\Logging.ps1
Write-Log -Message "Test" -LogFile "test.log" -LogChanges $true
```

## Migration from Original

Original `Manage-Settings.ps1` (1138 lines) was refactored into:
1. **5 PowerShell modules** (~342 lines): Core business logic
2. **C# GUI** (~425 lines): User interface with interaction logging
3. **Orchestrator** (~100 lines): Module loader and operation dispatcher

**Benefits**:
- **Maintainability**: Small focused modules instead of monolithic script
- **Debugging**: Easier to isolate issues in specific modules
- **GUI**: Modern Windows interface replaces terminal menu
- **Logging**: Comprehensive interaction tracking for debugging
- **Testability**: Modules can be tested independently

## Troubleshooting

### Compilation Errors

**Issue**: `System.Management.Automation.dll not found`
**Solution**: 
1. Install PowerShell SDK: `Install-Package -Name Microsoft.PowerShell.SDK`
2. Or reference from GAC: `C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Management.Automation\v4.0_3.0.0.0__31bf3856ad364e35\System.Management.Automation.dll`
3. Or simplify C# to use Process.Start("powershell.exe") instead of SDK

**Issue**: `Microsoft.VisualBasic.dll not found`
**Solution**: Use TextBox input dialog instead of InputBox, or install Visual Basic runtime

### Runtime Errors

**Issue**: Module not found
**Solution**: Verify modules/powershell/ directory exists and contains .ps1 files

**Issue**: Settings file not found
**Solution**: Verify modules/config/settings.ini exists, or create default

**Issue**: PowerShell execution policy
**Solution**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Development Workflow

### Adding a New Module

1. Create `modules/powershell/NewModule.ps1`
2. Define functions with Export-ModuleMember
3. Add module name to `$modulesToLoad` array in Settings-Manager.ps1
4. Test module independently
5. Integrate with C# GUI by adding new operation to Invoke-SettingsOperation

### Adding a New GUI Feature

1. Edit `modules/csharp/SettingsManagerGUI.cs`
2. Add button/control to InitializeComponents()
3. Create event handler
4. Add logging calls
5. Recompile with `compile.bat`
6. Test in automated environment

## Future Enhancements

- **Settings validation**: Schema-based validation of settings values
- **Backup/restore**: Automated backups before changes
- **Dark mode**: Alternate color scheme
- **Search/filter**: Find settings by key name
- **Multi-file**: Support multiple settings files
- **Localization**: Multi-language support

## Copilot Instructions Compliance

This refactored implementation follows all requirements:
- ✅ Modular architecture (5 PowerShell modules)
- ✅ Single executable (Settings-Manager.exe)
- ✅ GUI with interaction logging
- ✅ Explicit module loading (security)
- ✅ Config files in modules/config/
- ✅ _runspace instead of run_space
- ✅ Debug features preserved
- ✅ Automated testing support
- ✅ Comprehensive logging
- ✅ Error handling and cleanup

## Release & Versioning Workflow

- Build the executable inside `_debug/automated_testing_environment/` only.
- After a successful build, move the fresh `Settings-Manager.exe` to the program root (same folder as `run.bat`).
- Maintain a version tracker at `_debug/version_tracker.txt` (CSV: Version,File,Timestamp,Notes).
- Archive each build to `_debug/backups/Settings-Manager_v{N}.exe` starting at version 0 (baseline recorded 2025-12-05).
- Increment the version number on every new build you promote from the testing environment.
- Auto-run sanity check after each build (compile_simple.bat). Use `KEEP_GUI_OPEN=1` to keep the GUI running for interactive debugging; otherwise it auto-launches, waits 5s, and closes.

## Support & Diagnostics Expectations

- When users hit errors or report trouble, **check log files first** and request screenshots if symptoms are unclear.
- Preserve keystroke logs to help reconstruct user actions; `keyboard.log` records keypresses with timestamps and active control.
- Use captured keystrokes and logs to reproduce UI states seen in screenshots and override/fix values if needed.
