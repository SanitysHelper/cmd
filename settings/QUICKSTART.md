# Settings Manager - Quick Start Guide

## Installation

1. **Compile** (if not already compiled):
   ```batch
   compile_simple.bat
   ```

2. **Run**:
   - Double-click `Settings-Manager.exe` (GUI mode)
   - Or run `run.bat` for CLI mode (legacy)

## GUI Features

### Main Window
- **DataGridView**: Displays all settings in a table
  - Columns: Section | Key | Value | Description
  - Values are directly editable in the grid
- **Button Menu** (numbered for keyboard shortcuts):
  1. View All - Reload settings from file
  2. Edit Setting - Edit selected setting in dialog
  3. Add Setting - Add new setting
  4. Reload - Reload from file (discards unsaved changes)
  5. Save - Save changes to file
  6. Debug Menu - View debug information
  7. Quit - Exit application
- **Log Panel** (bottom): Real-time activity log
  - Black background, green text
  - Timestamps on all events
  - Logs: button clicks, cell edits, operations, errors

### Keyboard Shortcuts
- `Alt+1` through `Alt+7`: Access buttons
- `Enter`: Accept dialogs
- `Esc`: Cancel dialogs
- Arrow keys: Navigate grid

## Usage Scenarios

### View Settings
1. Launch Settings-Manager.exe
2. All settings are automatically loaded
3. Click "1. View All" to refresh

### Edit a Setting (Method 1 - Direct Edit)
1. Click on any cell in the "Value" column
2. Type new value
3. Press Enter
4. Click "5. Save" to persist changes

### Edit a Setting (Method 2 - Dialog)
1. Select a row by clicking
2. Click "2. Edit Setting"
3. Enter new value in dialog
4. Click OK
5. Click "5. Save" to persist

### Add a New Setting
1. Click "3. Add Setting"
2. Enter:
   - **Section**: e.g., "General", "Logging", "Advanced"
   - **Key**: e.g., "new_option"
   - **Value**: e.g., "true"
   - **Description**: e.g., "Enable new feature"
3. Click Add
4. Click "5. Save" to persist

### Reload from File
1. Click "4. Reload"
2. Confirm (unsaved changes will be lost)
3. Fresh data loaded from settings.ini

### Debug Information
1. Click "6. Debug Menu"
2. View:
   - Script directory
   - Settings file path
   - Total settings count
   - Log entries count

## File Locations

- **Settings**: `modules/config/settings.ini`
- **Internal Config**: `modules/config/.internal_config`
- **Logs**: `_debug/logs/` (if enabled)
- **Documentation**: `modules/config/README.md`

## Settings File Format

settings.ini uses INI format with comments:

```ini
[Section]
key=value # Description here
another_key=another_value # Another description
```

Example:
```ini
[General]
debug_mode=false # Enable debug features
timeout_seconds=300 # Execution timeout

[Logging]
log_input=true # Log user inputs
log_error=true # Log errors
```

## Troubleshooting

### "Settings file not found"
- Ensure `modules/config/settings.ini` exists
- Check log panel for full path
- Verify directory structure

### "Cannot save settings"
- Check file permissions
- Ensure settings.ini is not open in another program
- Verify disk space

### GUI doesn't start
- Ensure .NET Framework 4.0+ is installed
- Run from command line to see error messages:
  ```batch
  Settings-Manager.exe
  ```

### Changes not persisting
- You must click "5. Save" to write changes
- Check log panel for save confirmation
- Verify no error messages in log

## Log Panel Interpretation

Messages follow this format:
```
[YYYY-MM-DD HH:MM:SS] Event description
```

Examples:
- `[2024-12-05 23:30:00] Button clicked: 1. View All`
- `[2024-12-05 23:30:15] Loaded 12 settings`
- `[2024-12-05 23:30:30] Value changed: debug_mode = true`
- `[2024-12-05 23:30:45] Settings saved successfully: 12 settings written`

## Tips

- **Direct editing is faster**: Click Value column and type
- **Use Tab**: Navigate between cells quickly
- **Watch the log**: Confirms all operations
- **Save often**: No auto-save feature
- **Backup first**: Copy settings.ini before major changes

## Advanced: CLI Mode

Legacy PowerShell interface (for scripting):

```batch
run.bat
```

Features:
- Text-based menu
- Piped input support for automation
- Same backend modules as GUI

## Next Steps

- See `MODULAR_ARCHITECTURE.md` for technical details
- Check `modules/config/README.md` for configuration options
- Review `_debug/logs/` for detailed operation logs

