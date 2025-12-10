# Manual Input Detection - Quick Reference

## How to Use

When testing or debugging and the program **hangs waiting for your input**:

**Press `P`** to trigger the critical error detector.

## What It Does

### Immediate Actions:
1. **Displays Error Message** in RED, clearly explaining the problem
2. **Logs Critical Error** to `_debug/logs/important.log`  
3. **Exits Program** with exit code 1 (failure)

### Error Message Tells You:
- What went wrong (manual input was required)
- Where to look (ReadKey/Read-Host/try-catch issues)
- What was expected (full automation, zero manual input)
- What actually happened (program blocked)

## Key Points

- **P = PROBLEM**: Program blocked, waiting for manual input in automated environment
- **Automatic Detection**: Knows if running in test environment
- **Zero False Positives**: Only triggers when P is pressed during automated mode
- **Clear Diagnostics**: Tells you exactly what to fix

## The Critical Error

If you ever have to press P:

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

## Common Scenarios

### Scenario 1: You're Testing Manually
- Normal keypresses work fine
- Press P? → Program flags it as error (intentional - you found a bug!)

### Scenario 2: Automated Test Hangs
- Pipeline/file-based input sent
- Program hits ReadKey() call
- You're forced to press a key
- Press P → Instantly logs and exits with error

### Scenario 3: Testing in Debug Environment
- Running in `automated_testing_environment` folder
- Press P → Automatically flagged as critical error
- No guessing - clear feedback

## Exit Codes

- **0**: Success (no manual intervention needed)
- **1**: Failure (P was pressed or other error)

## What Gets Logged

In `_debug/logs/important.log`:
```
[TIMESTAMP] INFO: *** CRITICAL: Manual input detected (P pressed) during automated environment ***
[TIMESTAMP] INFO: *** This indicates the program was HANGING and waiting for manual keypresses ***
[TIMESTAMP] INFO: *** The program should handle automated input gracefully without user interaction ***
```

## Design Philosophy

### The Core Rule:
> **ZERO manual input required. Ever.**

When testing or debugging, if the program EVER needs you to press a key:
- ✅ You discovered a critical bug
- ✅ The program blocks on user input
- ✅ It can't be automated
- ✅ The code needs fixing

Press P to log it and exit immediately.

## Examples of Fixed vs Broken Code

### BROKEN:
```powershell
# This blocks if no input available!
$value = Read-Host "Enter value"
```

### FIXED:
```powershell
# Handles missing input gracefully
try {
    $value = Read-Host "Enter value"
    if ([string]::IsNullOrWhiteSpace($value)) { break }
} catch {
    break
}
```

## Summary

The P key is your **diagnostic hotspot** for automated input handling bugs:
- Press it when the program blocks
- Instantly get clear error feedback
- Know exactly where the bug is
- Exit cleanly with failure code

**Never ship code that requires P to be pressed.**
