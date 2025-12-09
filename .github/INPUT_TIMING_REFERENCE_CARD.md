# Input Timing Tracking - Reference Card

## Quick Identification

### What to Look For in Logs

```
input.log:
  INPUT #1 (+0.05s)    ← AI automated ✅ Fast
  INPUT #2 (+0.03s)    ← AI automated ✅ Fast  
  INPUT #3 (+7.2s) [DELAY: MANUAL INPUT SUSPECTED] ← ❌ Slow! Manual input required!
  INPUT #4 (+0.10s)    ← AI automated ✅ Fast
```

### The Three Scenarios

| Log Pattern | Timing | Meaning |
|-------------|--------|---------|
| Multiple inputs all <0.2s | 0.01-0.10s | ✅ Program fully automated |
| One input >2s [DELAY] | 5+ seconds | ❌ User had to manually type here |
| PROMPT_WAIT_START, no END | ∞ seconds | ❌ Program hung/blocked waiting |

---

## Implementation Checklist

**To add to a program:**
- [ ] Line 1: `$script:lastInputTime = Get-Date`
- [ ] Line 2: `$script:inputCounter = 0`
- [ ] Add Log-Input function with source parameter
- [ ] Add Log-InputTiming function  
- [ ] Wrap each input: `Log-InputTiming -Action "WAIT_START"`
- [ ] Log the input: `Log-Input -Message $input -Source "Menu"`
- [ ] Wrap after: `Log-InputTiming -Action "WAIT_END"`
- [ ] Settings: `log_input=true`

**Time required: 5 minutes**

---

## Log Reading Guide

### input.log

```log
[2025-12-07 00:36:28] INPUT #1 [NumberedMenu] (+0.8839081s): 11
 ↑                     ↑   ↑   ↑                 ↑           ↑
 Timestamp            Counter Source            Timing      Input
                                               (since last)
```

**Analysis**:
- First input gets system boot time (0.8s normal)
- Subsequent inputs: <0.2s = automated ✅
- Any input: >2s = manual input ⚠️

### input-timing.log

```log
[2025-12-07 00:36:28] PROMPT_WAIT_START | Numbered menu awaiting input
[2025-12-07 00:36:28] PROMPT_WAIT_END | Input received
```

**Analysis**:
- Event markers show program waiting
- Match START with END on next line = normal ✅
- START without matching END = program hung ❌

---

## Decision Tree: Is My Program Automated?

```
1. Run test with piped input
   "input1\ninput2\nq\n" | .\program.bat
   ↓
2. Check input.log
   ├─ All inputs <0.2s apart?
   │  └─ YES → Program fully automated ✅
   │  
   └─ Any input with [DELAY: Xs] where X>2?
      └─ YES → User had to manually type here ❌
              → Problem: Read-Host or input blocking
              → Solution: Add null check + try-catch
   ↓
3. Check input-timing.log
   ├─ All START lines have END lines?
   │  └─ YES → Normal operation ✅
   │
   └─ Any START without matching END?
      └─ YES → Program hung waiting for input ❌
              → Problem: Blocking read without timeout
              → Solution: Add timeout logic
   ↓
4. Conclusion:
   • No delays + matched events = Fully automated ✅
   • Any delays OR unmatched events = Issues found ❌
```

---

## Common Issues & Fixes

### Issue 1: [DELAY: 5.2s - MANUAL INPUT SUSPECTED]

**What it means**: Program waited 5 seconds between inputs - user manually typed

**Where to look**: 
```powershell
Read-Host "Enter number"  ← This is blocking without timeout
```

**Fix**:
```powershell
try {
    $input = if ([Console]::IsInputRedirected) {
        [Console]::In.ReadLine()
    } else {
        Read-Host "Enter number"
    }
} catch {
    exit 0  # Handle pipe exhaustion gracefully
}
```

### Issue 2: PROMPT_WAIT_START with no PROMPT_WAIT_END

**What it means**: Program started waiting but never got input (hung)

**Where to look**: Any blocking operation:
```powershell
while ($true) {
    $key = $Host.UI.RawUI.ReadKey()  ← This has no timeout!
}
```

**Fix**:
```powershell
$timeout = New-TimeSpan -Seconds 30
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

while ($stopwatch.Elapsed -lt $timeout) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey()
        # process key
        break
    }
    Start-Sleep -Milliseconds 100
}
```

### Issue 3: No logs at all

**What it means**: Logging disabled or not initialized

**Check**:
```powershell
# In settings.ini, must have:
[Logging]
log_input=true

# In code, check:
if (-not $script:settings.Logging.log_input) { return }
```

**Fix**: Enable in settings.ini

---

## Test Template

```powershell
# Clear logs
cd _debug/automated_testing_environment
Remove-Item _debug/logs/* -Force -ErrorAction SilentlyContinue

# Run with piped input
"1`n2`n3`nq`n" | .\run.bat

# Check timing
Write-Host "=== INPUT TIMING ===" 
Get-Content _debug/logs/input.log | Select-Object -First 10

# Check events
Write-Host "=== WAIT EVENTS ===" 
Get-Content _debug/logs/input-timing.log | Select-Object -First 10

# Analyze
Write-Host "=== ANALYSIS ==="
Write-Host "✓ All inputs <0.2s? → Automated"
Write-Host "✓ Any [DELAY]? → Manual input required"
Write-Host "✓ START/END matched? → Normal operation"
```

---

## Reference: Timing Thresholds

| Range | Meaning | Action |
|-------|---------|--------|
| <0.01s | Ultra-fast (internal) | ✅ Fine |
| 0.01-0.10s | AI fast (automated) | ✅ Fine |
| 0.10-0.50s | Normal variation | ✅ Fine |
| 0.50-2.0s | Slow but possible | ⚠️ Check |
| >2.0s | [DELAY] warning | ❌ Manual input! |

---

## Key Functions Reference

### Log-Input
```powershell
Log-Input -Message "user input" -Source "MenuType"

# Generates:
# [time] INPUT #N [Source] (+Xs) [DELAY warning]: user input
```

### Log-InputTiming  
```powershell
Log-InputTiming -Action "PROMPT_WAIT_START" -Details "waiting"
# Later:
Log-InputTiming -Action "PROMPT_WAIT_END" -Details "received"

# Generates:
# [time] PROMPT_WAIT_START | waiting
# [time] PROMPT_WAIT_END | received
```

---

## Files Location

| Purpose | Location |
|---------|----------|
| Implementation guide | `.github/copilot-instructions.md` Section 14 |
| Full reference | `.github/INPUT_TIMING_IMPLEMENTATION_SUMMARY.md` |
| Program guide | `uiBuilder/_debug/INPUT_TIMING_SYSTEM.md` |
| Quick start | `uiBuilder/_debug/INPUT_TIMING_QUICK_START.md` |
| Input logs | `_debug/logs/input.log` (any program) |
| Event logs | `_debug/logs/input-timing.log` (any program) |

---

## Remember

- **>2 seconds = RED FLAG** (user had to manually type)
- **START without END = HUNG** (program blocked forever)
- **All <0.2s = AUTOMATED** (working correctly)
- **No logs = Not enabled** (check settings.ini)

**Bottom line**: These logs tell the complete story of whether manual input was required during testing.
