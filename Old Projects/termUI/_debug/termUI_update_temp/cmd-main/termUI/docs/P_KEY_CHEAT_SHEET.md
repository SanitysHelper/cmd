# P Key - Developer Cheat Sheet

## TL;DR

- **Problem**: Program hangs waiting for manual input during automated tests
- **Solution**: Press `P` to instantly flag and exit
- **Result**: Clear error message + log entry + exit code 1

## When to Press P

| Situation | Action |
|-----------|--------|
| Program hangs during automated test | Press **P** |
| Program blocks on ReadKey() call | Press **P** |
| Program blocks on Read-Host call | Press **P** |
| You must manually intervene in test | Press **P** |
| Any blocking on user input | Press **P** |

## What Happens After P Press

1. **Red Error Message** appears (unmissable)
2. **Critical Log Entry** written to important.log
3. **Program Exits** immediately with code 1
4. **You Know** exactly what to fix

## Error Message Shows

```
Root Cause: Missing ReadKey() null check or try-catch block
Location: Check these areas:
  1. ReadKey() calls without IsTestMode check
  2. Read-Host calls without proper error handling
  3. Input operations not wrapped in try-catch blocks
```

## Common Fixes

### Fix 1: Wrap ReadKey
```powershell
# BROKEN:
$null = $host.UI.RawUI.ReadKey()

# FIXED:
if (-not ($handler.PSObject.Properties['IsTestMode'] -and $handler.IsTestMode)) {
    $null = $host.UI.RawUI.ReadKey()
}
```

### Fix 2: Wrap Read-Host
```powershell
# BROKEN:
$value = Read-Host "Enter:"

# FIXED:
try {
    $value = Read-Host "Enter:"
    if ([string]::IsNullOrWhiteSpace($value)) { break }
} catch {
    break
}
```

### Fix 3: Check for Null Input
```powershell
# BROKEN:
$input = Read-Host  # Will hang if no input

# FIXED:
$input = Read-Host
if ([string]::IsNullOrWhiteSpace($input)) { 
    exit 0  # Graceful exit
}
```

## Code Locations

| Component | File | Lines |
|-----------|------|-------|
| P Key Handler | termUI.ps1 | 152-177 |
| Initialization | termUI.ps1 | 15-16 |
| Environment Detection | termUI.ps1 | 43 |
| Exit Handler | termUI.ps1 | 323-327 |
| Logging | important.log | Runtime |

## Exit Codes

```
0 = Success (no manual input needed)
1 = Failure (P was pressed or error occurred)
```

## Testing

```powershell
# Run program
cd termUI
.\run.bat

# Press P when it hangs
# Result: Exit code 1, error message displayed

# Check code:
echo "Exit code: $LASTEXITCODE"
```

## Rules

✅ **DO**:
- Check `IsTestMode` before blocking calls
- Wrap input in try-catch blocks
- Handle null/empty input
- Test with piped input
- Support zero manual interaction

❌ **DON'T**:
- Call ReadKey() without mode check
- Use Read-Host without error handling
- Assume input is always available
- Block on user input in tests
- Ignore pipe exhaustion

## The Goal

**ZERO manual input required. Ever.**

If you ever have to press P, there's a bug.

Press P → Fix bug → Never press P again.

## Quick Diagnostic

When someone says "Program hangs":

1. Ask them to **press P**
2. Get immediate error message
3. Know exactly where bug is
4. No guessing, no debugging time

## Documentation

- **Quick Ref**: P_KEY_QUICK_REF.md
- **Full Docs**: MANUAL_INPUT_DETECTION.md
- **Implementation**: IMPLEMENTATION_COMPLETE_P_KEY.md
- **Code**: termUI.ps1 (lines 15-16, 43, 152-177, 323-327)

## Remember

**P = PROBLEM**

The program is blocked, waiting for manual input in an automated environment.

Press it. Fix it. Done.
