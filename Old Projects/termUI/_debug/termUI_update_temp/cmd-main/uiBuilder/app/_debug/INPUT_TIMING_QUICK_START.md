# Input Timing Tracking - Quick Start Guide

## For Future Programs

### When to Add Input Timing

Add input timing tracking to ANY program that:
- Accepts user input (Read-Host, menu selections, keyboard input)
- Runs in automated testing (piped input)
- Needs to detect if waiting for manual keypresses during testing

### 5-Minute Implementation

**1. Add to main script (2 lines)**:
```powershell
$script:lastInputTime = Get-Date
$script:inputCounter = 0
```

**2. Create enhanced Log-Input function**:
```powershell
function Log-Input {
    param([string]$Message, [string]$Source = "Unknown")
    if (-not $script:settings.Logging.log_input) { return }
    
    $currentTime = Get-Date
    $timeSinceLastInput = ($currentTime - $script:lastInputTime).TotalSeconds
    $script:lastInputTime = $currentTime
    $script:inputCounter++
    
    $delayIndicator = ""
    if ($timeSinceLastInput -gt 2.0 -and $script:inputCounter -gt 1) {
        $delayIndicator = " [DELAY: ${timeSinceLastInput}s - MANUAL INPUT SUSPECTED]"
    }
    
    $logFile = Join-Path $script:logsPath "input.log"
    $timingInfo = "(+${timeSinceLastInput}s)"
    "[$(Get-Timestamp)] INPUT #$($script:inputCounter) [$Source] $timingInfo${delayIndicator}: $Message" | Add-Content -Path $logFile -Encoding UTF8
}
```

**3. Create timing event log function**:
```powershell
function Log-InputTiming {
    param([string]$Action, [string]$Details = "")
    if (-not $script:settings.Logging.log_input) { return }
    
    $logFile = Join-Path $script:logsPath "input-timing.log"
    $timestamp = Get-Timestamp
    "[$timestamp] $Action | $Details" | Add-Content -Path $logFile -Encoding UTF8
}
```

**4. Wrap input operations**:
```powershell
# Before waiting
Log-InputTiming -Action "PROMPT_WAIT_START" -Details "menu waiting"

# Read input
$input = Read-Host "Prompt"

# After input
Log-InputTiming -Action "PROMPT_WAIT_END" -Details "received"

# Log it
Log-Input -Message $input -Source "MenuType"
```

### Reading the Logs

**input.log** - Timing between inputs:
```log
[2025-12-07 00:36:28] INPUT #1 [Menu] (+0.88s): value1
[2025-12-07 00:36:28] INPUT #2 [Menu] (+0.03s): selected
[2025-12-07 00:36:35] INPUT #3 [Menu] (+7.2s) [DELAY: 7.2s - MANUAL INPUT SUSPECTED]: q
```

- <0.2s timing = AI automated ✅
- >2.0s timing = Manual input ⚠️
- [DELAY] warning = User had to type manually ❌

**input-timing.log** - Wait events:
```log
[2025-12-07 00:36:28] PROMPT_WAIT_START | menu awaiting input
[2025-12-07 00:36:28] PROMPT_WAIT_END | received
[2025-12-07 00:36:28] PROMPT_WAIT_START | menu awaiting input
(no END - program hung!)
```

- Matching START/END = Normal ✅
- START without END = Program hung ❌

### Troubleshooting

| Problem | Check | Fix |
|---------|-------|-----|
| Manual input required | `input.log` for >2s delays | Add null checks to `Read-Host` |
| Program hangs | `input-timing.log` for START without END | Wrap input in try-catch |
| Inconsistent timing | Check if piped input is working | Verify pipe: `"input\n" \| .\run.bat` |
| No delay detected | Settings: `log_input=true` | Enable logging in settings.ini |

### Quick Test

```powershell
# Clear logs
Remove-Item _debug/logs/* -Force -ErrorAction SilentlyContinue

# Run with piped input
"menu_choice1`nmenu_choice2`nq`n" | .\run.bat

# Check timing
Get-Content _debug/logs/input.log

# All inputs should show <0.2s timing
# If any >2s, user had to manually type
```

### Real Example: uiBuilder

**Implementation Files**:
- Main: `UI-Builder.ps1` (2 variables added)
- Logger: `modules/logging/Logger.ps1` (2 functions added)
- Menu: `modules/ui/MenuDisplay.ps1` (timing calls added around input)

**Logs Generated**:
- `_debug/logs/input.log` - Timing for every input
- `_debug/logs/input-timing.log` - Wait event markers

**Test Results** (440 menu items, 6-level deep):
```log
INPUT #1 [NumberedMenu] (+0.88s): 11      ← AI piped input
INPUT #2 [NumberedMenu] (+0.03s): Selected: 10   ← 0.03s later ✅
INPUT #3 [NumberedMenu] (+0.10s): 1       ← 0.10s later ✅
All timings <0.2s = Fully Automated ✅
```

### Key Principles

1. **Fast timing = Automated AI** (<0.1s)
2. **Slow timing = Manual user** (>2.0s)
3. **>2 seconds = RED FLAG** - Program required manual input
4. **No matching END = FROZEN** - Program hung waiting

### When You See Problems

**Issue**: Timing log shows 5+ second delay
```
[DELAY: 5.234567s - MANUAL INPUT SUSPECTED]
```

**What happened**: Program blocked waiting for manual keypress. The AI couldn't automate input here.

**What to fix**: 
1. Check the code - is Read-Host blocking without timeout?
2. Is input piped correctly? `"value\n" | .\run.bat`
3. Need to add null check and try-catch around Read-Host
4. Should accept piped input gracefully and exit if not available

### One-Command Copy-Paste (For New Programs)

```powershell
# Functions to paste into logging module
function Log-Input { param([string]$Message, [string]$Source = "Unknown"); if (-not $script:settings.Logging.log_input) { return }; $currentTime = Get-Date; $timeSinceLastInput = ($currentTime - $script:lastInputTime).TotalSeconds; $script:lastInputTime = $currentTime; $script:inputCounter++; $delayIndicator = ""; if ($timeSinceLastInput -gt 2.0 -and $script:inputCounter -gt 1) { $delayIndicator = " [DELAY: ${timeSinceLastInput}s - MANUAL INPUT SUSPECTED]" }; $logFile = Join-Path $script:logsPath "input.log"; $timingInfo = "(+${timeSinceLastInput}s)"; "[$(Get-Timestamp)] INPUT #$($script:inputCounter) [$Source] $timingInfo${delayIndicator}: $Message" | Add-Content -Path $logFile -Encoding UTF8 }
function Log-InputTiming { param([string]$Action, [string]$Details = ""); if (-not $script:settings.Logging.log_input) { return }; $logFile = Join-Path $script:logsPath "input-timing.log"; $timestamp = Get-Timestamp; "[$timestamp] $Action | $Details" | Add-Content -Path $logFile -Encoding UTF8 }
```

---

**Remember**: If a test requires manual input from you, the program isn't properly designed for automation. Use this timing system to find where it's blocking and fix it!
