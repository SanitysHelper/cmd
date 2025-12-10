# TermUILibrary Improvements Summary

## New Functions Added

### 1. **New-TermUIInputButton** (New Feature)
Creates input buttons that prompt users for text values rather than fixed options.

```powershell
# Create an input button that prompts for user name
New-TermUIInputButton -TermUIRoot $termUIRoot `
    -Path "UserInfo/Name" `
    -Prompt "Enter your name:" `
    -Description "This will be stored in your profile"
```

**Features:**
- Automatically handles `.input` file extension
- Creates intermediate directories as needed
- Supports multi-line descriptions
- Prompt appears on first line, description on subsequent lines

---

### 2. **Invoke-TermUISimulateButtonPress** (New Feature)
Simulates pressing a button by name for automated testing and programmatic control.

```powershell
# Simulate pressing the "Settings" button
Invoke-TermUISimulateButtonPress -TermUIRoot $termUIRoot `
    -MenuPath "mainUI" `
    -ButtonName "Settings"

# Simulate pressing an input button and provide a value
Invoke-TermUISimulateButtonPress -TermUIRoot $termUIRoot `
    -MenuPath "mainUI/TextInput" `
    -ButtonName "UserName" `
    -InputValue "John Doe"
```

**Features:**
- Finds buttons by displayed name
- Works with both option and input buttons
- Supports timeout control
- Returns selection result for verification

---

### 3. **Get-TermUIMenuStructure** (Improvement #2)
Inspects and returns available buttons at a menu level.

```powershell
# Get all buttons in mainUI
$structure = Get-TermUIMenuStructure -TermUIRoot $termUIRoot

# Find all input buttons
$inputButtons = $structure | Where-Object { $_.Type -eq "input" }

# List all submenus
$structure | Where-Object { $_.Type -eq "submenu" } | Select-Object -ExpandProperty Name
```

**Features:**
- Returns structured data about buttons and submenus
- Includes button type (option/input/submenu)
- Extracts prompts from input buttons
- Useful for menu exploration and validation

---

### 4. **Get-TermUISelectionValue** (Improvement #4)
Safely extracts values from selection results with flexible output options.

```powershell
# Get just the value
$value = Get-TermUISelectionValue -SelectionResult $result

# Get value with path and name info
$details = Get-TermUISelectionValue -SelectionResult $result -IncludePath -IncludeName

# Handle null results gracefully
if ($null -eq (Get-TermUISelectionValue -SelectionResult $result)) {
    Write-Host "No value returned"
}
```

**Features:**
- Handles null results gracefully
- Extracts value from input buttons
- Optional path and name information
- Cleaner code than direct property access

---

### 5. **Test-TermUIInputButton** (Improvement #4)
Determines if a selection result is from an input button.

```powershell
$result = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI"

if (Test-TermUIInputButton -SelectionResult $result) {
    $userValue = $result.value
    Write-Host "User entered: $userValue"
} else {
    Write-Host "User selected option: $($result.name)"
}
```

**Features:**
- Returns boolean for easy conditional logic
- Complements existing `Test-TermUIQuit` function
- Reduces need for null/property checks

---

## Five Key Improvements Implemented

### **Improvement #1: Input Validation & Path Verification**
**Location:** `Invoke-TermUISelection` function

Before: No validation of TermUIRoot or MenuPath parameters.
After: Added `Test-Path` validation with helpful error messages.

```powershell
# Now throws helpful error instead of cryptic path errors
if (-not (Test-Path $TermUIRoot)) {
    throw "TermUI root directory not found: $TermUIRoot"
}
```

**Benefit:** Faster debugging when paths are wrong.

---

### **Improvement #2: Menu Structure Inspection**
**Location:** New `Get-TermUIMenuStructure` function

Before: No way to programmatically explore menu structure.
After: New function returns all buttons, submenus, and their metadata.

**Benefits:**
- Generate dynamic menus based on available buttons
- Validate menu structure programmatically
- Automated testing of menu availability
- Menu documentation generation

---

### **Improvement #3: Comprehensive Input Validation**
**Location:** `Invoke-TermUISimulateButtonPress` function

Before: Basic parameter validation.
After: Explicit checks with descriptive error messages for all parameters.

```powershell
if ([string]::IsNullOrWhiteSpace($MenuPath)) {
    throw "MenuPath cannot be empty"
}
if ([string]::IsNullOrWhiteSpace($ButtonName)) {
    throw "ButtonName cannot be empty"
}
```

**Benefit:** Users get clear feedback when parameters are incorrect.

---

### **Improvement #4: Flexible Result Extraction**
**Location:** New `Get-TermUISelectionValue` and `Test-TermUIInputButton` functions

Before: Users had to manually access `$result.value`, `$result.path`, `$result.name` with null checks.
After: Helper functions handle extraction with options for what to include.

```powershell
# Before (error-prone):
if ($result -and $result.value) {
    $value = $result.value
}

# After (cleaner):
$value = Get-TermUISelectionValue -SelectionResult $result
if (Test-TermUIInputButton -SelectionResult $result) { ... }
```

**Benefits:**
- Cleaner, more readable code
- Less repetition across programs
- Consistent error handling

---

### **Improvement #5: Auto-Value Handling for Input Buttons**
**Location:** `Invoke-TermUISimulateButtonPress` function

Before: No built-in support for input button values in simulation.
After: Automatically handles input button value passing.

```powershell
# Simulates button press and provides input in one call
$result = Invoke-TermUISimulateButtonPress `
    -TermUIRoot $termUIRoot `
    -MenuPath "mainUI/TextInput" `
    -ButtonName "UserName" `
    -InputValue "John Doe"

# Result includes the provided value
Write-Host "User entered: $($result.value)"  # "John Doe"
```

**Benefits:**
- Simpler automated testing
- Less code for common scenarios
- Type-safe value passing

---

## Function Reference

| Function | Purpose | Parameters |
|----------|---------|-----------|
| `New-TermUIButton` | Create option button | TermUIRoot, Path, Description |
| `New-TermUIInputButton` | Create input button | TermUIRoot, Path, Prompt, Description |
| `Invoke-TermUISelection` | Launch menu & get selection | TermUIRoot, MenuPath, AutoIndex, AutoName, CaptureTimeoutMs |
| `Invoke-TermUISimulateButtonPress` | Simulate button press | TermUIRoot, MenuPath, ButtonName, InputValue, CaptureTimeoutMs |
| `Get-TermUIMenuStructure` | Inspect menu buttons | TermUIRoot |
| `Get-TermUISelectionValue` | Extract result value | SelectionResult, IncludePath, IncludeName |
| `Test-TermUIQuit` | Check if user quit | SelectionResult |
| `Test-TermUIInputButton` | Check if input button | SelectionResult |

---

## Usage Examples

### Create a Simple Menu with Input
```powershell
# Create menu structure
New-TermUIButton -TermUIRoot $termUIRoot -Path "Settings/General" -Description "General settings"
New-TermUIInputButton -TermUIRoot $termUIRoot -Path "Settings/Username" `
    -Prompt "Enter username:" -Description "Your display name"

# Get user selection
$result = Invoke-TermUISelection -TermUIRoot $termUIRoot -MenuPath "mainUI"

if (Test-TermUIQuit -SelectionResult $result) {
    Write-Host "User cancelled"
} elseif (Test-TermUIInputButton -SelectionResult $result) {
    $value = Get-TermUISelectionValue -SelectionResult $result
    Write-Host "User entered: $value"
} else {
    Write-Host "User selected: $($result.name)"
}
```

### Automated Menu Testing
```powershell
# Test that all buttons exist and are accessible
$structure = Get-TermUIMenuStructure -TermUIRoot $termUIRoot

foreach ($button in $structure) {
    Write-Host "Testing button: $($button.Name) [$($button.Type)]"
    
    if ($button.Type -eq "input") {
        $result = Invoke-TermUISimulateButtonPress `
            -TermUIRoot $termUIRoot `
            -MenuPath "mainUI" `
            -ButtonName $button.Name `
            -InputValue "TestValue"
    } else {
        $result = Invoke-TermUISimulateButtonPress `
            -TermUIRoot $termUIRoot `
            -MenuPath "mainUI" `
            -ButtonName $button.Name
    }
    
    if ($result) {
        Write-Host "  ✓ Success: $($result.name)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed" -ForegroundColor Red
    }
}
```

---

## Backward Compatibility

All improvements are **100% backward compatible**:
- Existing functions work unchanged
- New parameters are optional
- Old code continues to work
- New functionality is additive only

---

## Summary

The enhanced TermUILibrary now provides:
✅ Better error handling and validation  
✅ Menu structure inspection capabilities  
✅ Input button creation and simulation  
✅ Flexible result extraction  
✅ Improved developer experience  
✅ Easier automated testing  
✅ More readable, maintainable code  
