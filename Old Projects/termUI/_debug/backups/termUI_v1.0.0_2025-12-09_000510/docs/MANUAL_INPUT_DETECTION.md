# Manual Input Detection - Critical Debugging Feature

## Overview

This feature detects when the program is **blocking and waiting for manual keypresses** during automated testing. This is a CRITICAL BUG that indicates the program cannot handle fully automated input.

## The Problem

When running automated tests, the program should:
- ✅ Accept input from piped sources (files, stdin)
- ✅ Process input gracefully when available
- ✅ Never block waiting for user keypresses
- ✅ Exit cleanly without manual intervention

If you must **manually press a key** during an automated test, it means:
- ❌ The program hit a blocking `ReadKey()` call
- ❌ Input handling isn't properly checking for automated mode
- ❌ There's a missing try-catch or null check
- ❌ The program is incompatible with CI/CD automation

## How to Use This Feature

### During Automated Testing:
If the program hangs and you must manually intervene:

**Press `P`** to flag the critical error

### What Happens When You Press P:

1. **Immediate Feedback**: Large red error message displays explaining the issue
2. **Log Entry**: `_debug/logs/important.log` gets critical error details
3. **Program Exits**: Exit code 1 (failure) indicating automated test failure
4. **Clear Guidance**: Error message tells you where to look in the code

### Error Message Example:

```
========================================================================
CRITICAL ERROR: Manual Input Required

The program was blocked waiting for your keypress.
This is a CRITICAL BUG in automated input handling.

Root Cause: Missing ReadKey() null check or try-catch block
Location: Check these areas:
  1. ReadKey() calls without IsTestMode check
  2. Read-Host calls without proper error handling
  3. Input operations not wrapped in try-catch blocks

Expected: Program should accept piped/automated input only
Actual: Program blocked waiting for manual keystroke
========================================================================
```

## Technical Details

### Variables Added:

```powershell
$script:manualInputDetected = $false    # Flag set when P is pressed
$script:isTestEnvironment = $false      # Detects if running in test folder
```

### Detection Logic:

```powershell
if ($script:isTestEnvironment -or $handler.PSObject.Properties['IsInteractive']) {
    # P key pressed during test/automated environment = CRITICAL ERROR
    $script:manualInputDetected = $true
    # Log critical error
    # Display error message
    # Exit with code 1
}
```

### Environment Detection:

The system automatically detects if it's running in an automated test environment by checking for the presence of the `automated_testing_environment` folder.

## Common Issues and Fixes

### Issue 1: ReadKey() Blocking in Test Mode
**Symptom**: You press P during a test
**Cause**: Code calls `$host.UI.RawUI.ReadKey()` without checking `IsTestMode`
**Fix**: Wrap in condition:
```powershell
if (-not ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode)) {
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
```

### Issue 2: Read-Host Without Error Handling
**Symptom**: Program hangs on input prompt
**Cause**: `Read-Host` blocks when input stream is empty
**Fix**: Add try-catch and null check:
```powershell
try {
    $input = Read-Host -Prompt "Enter value"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $null
    }
} catch {
    return $null
}
```

### Issue 3: No Automated Input Support
**Symptom**: Program requires manual prompts even with piped input
**Cause**: Design doesn't support input piping
**Fix**: Redesign to accept input from all sources:
- stdin/piped data
- Command-line arguments
- Environment variables
- Input files

## Design Principles

### MUST DO:
- ✅ Check `IsTestMode` before calling blocking input functions
- ✅ Wrap input operations in try-catch blocks
- ✅ Handle null/empty input gracefully
- ✅ Support piped input from day one
- ✅ Design for zero manual interaction

### MUST NOT DO:
- ❌ Call `ReadKey()` without mode check
- ❌ Use `Read-Host` without error handling
- ❌ Assume input will always be available
- ❌ Block on user input in automated context
- ❌ Ignore pipe exhaustion

## Integration with Testing

### Proper Test Mode Flow:

```
1. Test environment detected (auto)
   ↓
2. Program starts in automated mode
   ↓
3. Provide test inputs via piping/file
   ↓
4. Program processes inputs without blocking
   ↓
5. Program exits cleanly with code 0 (success)
   
OR

5. User presses P (manual intervention needed)
   ↓
6. Critical error logged and displayed
   ↓
7. Program exits with code 1 (failure)
```

## Exit Codes

- **Exit 0**: Success - program completed without manual intervention
- **Exit 1**: Failure - manual input detected (P pressed) or critical error

## Logging

All manual input detection is logged to `_debug/logs/important.log`:

```
[2025-12-08 13:20:15] INFO: *** CRITICAL: Manual input detected (P pressed) during automated environment ***
[2025-12-08 13:20:15] INFO: *** This indicates the program was HANGING and waiting for manual keypresses ***
[2025-12-08 13:20:15] INFO: *** The program should handle automated input gracefully without user interaction ***
```

## Example: Fixing a Hanging Program

### Before (Broken):
```powershell
while ($true) {
    Write-Host "Select option: "
    $choice = Read-Host  # HANGS if no input available!
    if ($choice -eq "q") { break }
}
```

### After (Fixed):
```powershell
while ($true) {
    Write-Host "Select option: "
    try {
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { break }
    } catch {
        break  # Gracefully exit on input error
    }
    if ($choice -eq "q") { break }
}
```

### With Test Mode Support:
```powershell
$choice = Get-UserInput "Select option"
if ($null -eq $choice) { break }  # Pipe exhaustion
if ($choice -eq "q") { break }    # Quit command
```

## What P Really Means

**P = "PROBLEM"**

The P key is a diagnostic tool that translates to:
> "**P**rogram is blocked, waiting for **M**anual input in **A**utomated environment"

Use it to immediately flag and log critical input handling bugs.

## Verification Checklist

Before considering automated testing complete:

- [ ] No manual intervention needed during test
- [ ] Inputs accepted from piped sources
- [ ] Never had to press P to break out
- [ ] All inputs logged in input.log
- [ ] All actions logged in important.log
- [ ] Exit code 0 on successful completion
- [ ] Program handles empty/missing input gracefully
