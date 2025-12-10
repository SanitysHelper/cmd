# TermUILibrary Quick Reference

## Core Functions (Original)

### Invoke-TermUISelection
Launches termUI and captures user selection.

```powershell
$result = Invoke-TermUISelection -TermUIRoot "C:\path\to\termUI" -MenuPath "mainUI"
```

### Test-TermUIQuit
Check if user cancelled.

```powershell
if (Test-TermUIQuit -SelectionResult $result) { Write-Host "Cancelled" }
```

---

## New Functions (Improvements)

### New-TermUIInputButton
Create text input buttons.

```powershell
New-TermUIInputButton -TermUIRoot $root -Path "Folder/ButtonName" `
    -Prompt "Enter value:" -Description "Help text"
```

### Invoke-TermUISimulateButtonPress
Simulate button press (automated testing).

```powershell
$result = Invoke-TermUISimulateButtonPress -TermUIRoot $root `
    -MenuPath "mainUI" -ButtonName "OptionName" -InputValue "test"
```

### Get-TermUIMenuStructure
Get all buttons in a menu.

```powershell
$buttons = Get-TermUIMenuStructure -TermUIRoot $root
```

### Get-TermUISelectionValue
Extract value from result.

```powershell
$value = Get-TermUISelectionValue -SelectionResult $result
```

### Test-TermUIInputButton
Check if selection is input button.

```powershell
if (Test-TermUIInputButton -SelectionResult $result) { ... }
```

---

## Common Patterns

### Pattern 1: Simple Menu Selection
```powershell
$result = Invoke-TermUISelection -TermUIRoot $root -MenuPath "mainUI"
if (Test-TermUIQuit -SelectionResult $result) { exit }
Write-Host "Selected: $($result.name)"
```

### Pattern 2: Handle Input Buttons
```powershell
$result = Invoke-TermUISelection -TermUIRoot $root -MenuPath "mainUI"

if (Test-TermUIInputButton -SelectionResult $result) {
    $value = Get-TermUISelectionValue -SelectionResult $result
    Write-Host "User entered: $value"
}
```

### Pattern 3: Automated Testing
```powershell
$buttons = Get-TermUIMenuStructure -TermUIRoot $root

foreach ($btn in $buttons | Where-Object Type -eq "option") {
    $result = Invoke-TermUISimulateButtonPress `
        -TermUIRoot $root -MenuPath "mainUI" -ButtonName $btn.Name
    Write-Host "Button $($btn.Name): $(if ($result) { 'OK' } else { 'FAIL' })"
}
```

---

## Improvement #1: Input Validation
Functions now validate paths before use.

```powershell
# Error message if path doesn't exist:
# "TermUI root directory not found: C:\invalid\path"
```

---

## Improvement #2: Menu Inspection
Programmatically explore menu structure.

```powershell
$structure = Get-TermUIMenuStructure -TermUIRoot $root
$structure | Format-Table -Property Name, Type, Description
```

---

## Improvement #3: Better Error Messages
Clear error messages for parameter issues.

```powershell
# Instead of silent failure:
# "MenuPath cannot be empty"
# "ButtonName cannot be empty"
```

---

## Improvement #4: Flexible Result Extraction
Helper functions reduce boilerplate.

```powershell
# Before:
if ($result -and $result.PSObject.Properties['value']) {
    $val = $result.value
}

# After:
$val = Get-TermUISelectionValue -SelectionResult $result
```

---

## Improvement #5: Button Press Simulation
Simpler automated testing.

```powershell
# One call instead of manual input:
Invoke-TermUISimulateButtonPress -TermUIRoot $root `
    -MenuPath "mainUI/TextInput" -ButtonName "UserName" -InputValue "John"
```

---

## Returns

### Selection Result Object
```powershell
@{
    name  = "ButtonName"        # Button display name
    path  = "mainUI/ButtonName" # Full button path
    value = "user input"        # Only for input buttons
}
```

---

## Null Returns
Functions return `$null` if:
- User cancels/quits
- Menu path doesn't exist
- Button name not found
- Process exits with error

Check with: `if ($result) { ... }`
Or: `if (-not (Test-TermUIQuit -SelectionResult $result)) { ... }`
