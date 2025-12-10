# TermUI Development Suggestions

## Current State
termUI is a powerful modular menu framework. To make programming easier, here are suggestions:

### 1. **Text Input Mode (Future Enhancement)**
Currently, buttons for numbers require many files (0.opt, 1.opt, 2.opt, ..., 20.opt). Instead, add:
- `Add-TermUIInput` function to prompt for text input in termUI
- Accept numeric/text entry without pre-creating button files
- Example: User navigates to "ValueA", presses `[T]` for input, types "42", returns value
- Benefit: Reduces button proliferation; supports dynamic input

### 2. **Backspace Bug in MenuBuilder**
The backspace feature in termUI doesn't work properly:
- Current: Backspace clears the number buffer but doesn't re-render display
- Fix needed: Call render after backspace to show updated input state
- Location: `termUI.ps1` line ~350, `"Backspace"` case

### 3. **Button Metadata (Future)**
Instead of storing descriptions in .opt file content, use JSON metadata:
- File: `buttons/mainUI/ValueA/1.opt.meta` containing `{"description":"Set A to 1", "category":"input", "hidden":false}`
- Allows richer properties without polluting .opt file
- Could enable filtering/searching buttons by category

### 4. **Default Button Values**
Allow .opt files to contain a default/suggested value:
```
1.opt contains: "10"  # Default value when selected
operation/add.opt contains: "result"  # Callback target
```
Benefit: Single source of truth; programs can read button content as data, not just names.

### 5. **Submenu Shortcuts**
Add `--capture-submenu <path>` flag to skip intermediate menu navigation:
- termUI starts directly at "Calculator/ValueA" instead of traversing mainUI → SettingsCommand → ValueA
- Saves navigation steps for deep menus

### 6. **Button Inheritance/Templates**
Allow button templates to reduce duplication:
```
buttons/mainUI/_templates/NumericValue.opt
  -> Copy to ValueA/1.opt, ValueA/2.opt, etc. with auto-filled description
```

### 7. **TermUI Configuration per Program**
Add per-program config:
- `settings.ini` option: `inherit_buttons=true/false` (share mainUI across programs or use local)
- `highlight_color`, `selection_style`, `description_position` customization

### 8. **Program Registration**
Add auto-discovery feature:
- Programs define their buttons in `_meta/buttons.json`
- termUI scans all programs and merges buttons
- No need to manually create button files for each program

### 9. **Exit Codes & Return Values**
Enhance return data:
- Currently returns `{name, path}` on selection, `null` on quit
- Enhance: `{name, path, timestamp, selected_index, menu_depth}`
- Add option to return custom data from button's .opt file

### 10. **Validation & Safety**
Add input validation layer:
- `Add-TermUIButton -Path "..." -AllowedValues @(0..20)` validates selection is in range
- `-Format "integer"` enforces type checking before returning
- Prevents invalid data flowing to calling program

## Current Library Functions

### TermUIButtonLibrary.ps1
Create and manage button UI:
1. `Clear-TermUIButtons` - Wipe all buttons
2. `Add-TermUIButton` - Single button
3. `Add-TermUIButtonBatch` - Multiple buttons at once
4. `Add-TermUIButtonRange` - Range of numbers (0-20, etc.)
5. `Add-TermUIButtonChoice` - Choice options (operations, modes)

### TermUIFunctionLibrary.ps1
Attach executable code to buttons:
1. `Add-TermUIFunctionFromString` - Attach code as a string with explicit language
2. `Add-TermUIFunctionFromFile` - Attach code from a file (auto-detects language)
3. `Invoke-TermUIFunction` - Execute a button's attached function

Supported languages: PowerShell, Batch, Python, JavaScript, Bash, Ruby, Perl, VBScript, Lua, Go, Rust

## Example Usage

### Example 1: Create Buttons

```powershell
. .\\termUI\\powershell\\modules\\TermUIButtonLibrary.ps1

$termUIRoot = "C:\\cmd\\termUI"

# Clear existing
Clear-TermUIButtons -TermUIRoot $termUIRoot

# Build calculator
Add-TermUIButtonRange -TermUIRoot $termUIRoot -Folder "Calculator/ValueA" `
    -Values @(0,1,2,3,5,10,20) -DescriptionTemplate "A = {0}"

Add-TermUIButtonChoice -TermUIRoot $termUIRoot -Folder "Calculator/Operation" `
    -Choices @{"add"="Add numbers"; "subtract"="Subtract"; "multiply"="Multiply"; "divide"="Divide"}
```

### Example 2: Attach Functions to Buttons

```powershell
. .\\termUI\\powershell\\modules\\TermUIFunctionLibrary.ps1

$termUIRoot = "C:\\cmd\\termUI"

# Attach PowerShell code as string
$backupCode = @'
Write-Host "Starting backup..."
Copy-Item "C:\\data" -Destination "C:\\backup" -Recurse
Write-Host "Backup complete!"
'@
Add-TermUIFunctionFromString -TermUIRoot $termUIRoot -ButtonPath "Tools/Backup/daily.opt" `
    -Code $backupCode -Language "powershell"

# Attach from file (auto-detects language by extension)
Add-TermUIFunctionFromFile -TermUIRoot $termUIRoot -ButtonPath "Data/Process/analyze.opt" `
    -ScriptFile "C:\\scripts\\data_analysis.py"

# Execute button function
$scriptPath = "C:\\cmd\\termUI\\buttons\\mainUI\\Tools\\Backup\\daily.ps1"
Invoke-TermUIFunction -ButtonPath $scriptPath
```

## Roadmap

**Short term** (no refactor):
- [ ] Fix backspace display bug
- [ ] Add description templates to reduce duplication
- [ ] Add `--capture-submenu` flag

**Medium term** (backward compatible):
- [ ] Implement text input mode alongside button selection
- [ ] Add metadata layer (.opt.meta files)
- [ ] Program registry system

**Long term** (major refactor):
- [ ] Unified validation/return system
- [ ] Custom styling per program
- [ ] Plugin system for custom menu types
