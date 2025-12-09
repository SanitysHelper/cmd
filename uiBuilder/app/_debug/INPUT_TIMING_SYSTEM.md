# Input Timing Tracking System

**Created**: 2025-12-07  
**Purpose**: Detect when program waits for manual user input vs automated AI input

## Overview

The input timing system tracks **every input event** with timestamps to identify unusual delays that indicate the program is waiting for manual keypresses. This helps debug blocking input operations during automated testing.

## How It Works

### 1. Timing Variables (UI-Builder.ps1)
```powershell
$script:lastInputTime = Get-Date      # Last input timestamp
$script:inputCounter = 0               # Sequential input counter
$script:aiInputSource = $true          # Input source flag
```

### 2. Enhanced Log-Input Function
Every input logs:
- **Input counter**: Sequential number (#1, #2, #3...)
- **Source**: Where input came from (NumberedMenu, InteractiveMenu, etc.)
- **Timing**: Seconds since last input (+0.03s, +2.5s, etc.)
- **Delay warning**: If delay >2 seconds, marks as "MANUAL INPUT SUSPECTED"

### 3. Dedicated Timing Log (input-timing.log)
Tracks specific wait events:
- `PROMPT_WAIT_START` - Program begins waiting for input
- `PROMPT_WAIT_END` - Input received
- `INTERACTIVE_WAIT_START` - Interactive mode waiting for arrow keys
- `INTERACTIVE_WAIT_END` - Key received
- `DESCRIPTION_WAIT_START` - Description box displayed
- `DESCRIPTION_WAIT_END` - User closed description box
- `DEBUG_KEY_SIMULATED` - Debug mode simulated key

## Log Files

### input.log
```log
[2025-12-07 00:34:59] INPUT #1 [NumberedMenu] (+0.8152639s): 11
[2025-12-07 00:34:59] INPUT #2 [NumberedMenu] (+0.0332659s): Selected: 10
[2025-12-07 00:35:00] INPUT #3 [NumberedMenu] (+0.0753485s): 2
[2025-12-07 00:35:00] INPUT #4 [NumberedMenu] (+0.0126666s): Selected: 1
```

**Analysis**:
- AI input: 0.01-0.08s between inputs ✅ Fast, automated
- Manual input: >2.0s between inputs ⚠️ User typing

### input-timing.log
```log
[2025-12-07 00:34:59] PROMPT_WAIT_START | Numbered menu awaiting input
[2025-12-07 00:34:59] PROMPT_WAIT_END | Input received
[2025-12-07 00:34:59] PROMPT_WAIT_START | Numbered menu awaiting input
[2025-12-07 00:35:00] PROMPT_WAIT_END | Input received
```

**Analysis**:
- Matching START/END pairs: Normal operation ✅
- START without END: Program hung waiting for input ❌

## Detecting Manual Input

### Automated AI Input Pattern
- Delays: <0.1s consistently
- Source: Piped from `"input\n" | .\run.bat`
- Timing: Predictable, fast

### Manual User Input Pattern
- Delays: >2s (reading, thinking, typing)
- Source: Terminal keyboard
- Timing: Variable, slow

### Example: Manual Input Detected
```log
[2025-12-07 00:35:00] INPUT #4 [NumberedMenu] (+0.0126666s): 2
[2025-12-07 00:35:05] INPUT #5 [NumberedMenu] (+5.234567s) [DELAY: 5.234567s - MANUAL INPUT SUSPECTED]: q
```

**What Happened**: User manually typed "q" 5 seconds after automated input finished.

## Input Sources

| Source | Description | Typical Timing |
|--------|-------------|----------------|
| `NumberedMenu` | Text input from numbered menu | <0.1s (AI) or >2s (manual) |
| `InteractiveMenu` | Arrow key navigation | <0.1s (AI simulation) or >0.5s (manual) |
| `Unknown` | Internal selections (not directly from user) | <0.05s |

## Troubleshooting with Logs

### Problem: Program Hangs During Test
**Check**: `input-timing.log` for START without END
```log
[2025-12-07 00:35:00] PROMPT_WAIT_START | Numbered menu awaiting input
(no matching END - program stuck here!)
```

**Solution**: Add null check to input handling, ensure piped input works

### Problem: User Had to Type Manually During AI Test
**Check**: `input.log` for large delays
```log
[2025-12-07 00:35:00] INPUT #3 [NumberedMenu] (+0.05s): 2
[2025-12-07 00:35:15] INPUT #4 [NumberedMenu] (+15.2s) [DELAY: 15.2s - MANUAL INPUT SUSPECTED]: q
```

**Diagnosis**: Program waited 15 seconds (manual input required)  
**Solution**: Missing piped input value or Read-Host blocking incorrectly

### Problem: Unexpected Behavior After Input
**Check**: Both logs to correlate timing with actions
```log
input-timing.log:
[2025-12-07 00:35:00] INTERACTIVE_WAIT_START | Waiting for arrow key input
[2025-12-07 00:35:02] INTERACTIVE_WAIT_END | Key received: VK=40

input.log:
[2025-12-07 00:35:02] INPUT #5 [InteractiveMenu] (+2.1s) [DELAY: 2.1s - MANUAL INPUT SUSPECTED]: Key: 40 (␀), Shift: False
```

**Diagnosis**: 2.1s delay suggests manual arrow key press (VK=40 is Down arrow)  
**Expected**: AI should simulate keys with <0.1s timing

## Settings Configuration

Enable timing logs in `settings.ini`:
```ini
[Logging]
log_input=true        # Required for input.log
log_important=true    # For important state changes
log_error=true        # For error tracking
```

## Usage Examples

### Test 1: Fast AI Input (Expected)
```powershell
"11\n2\nq\n" | .\run.bat
```

**Expected Logs**:
- All inputs <0.2s apart
- No DELAY warnings
- All START/END pairs matched

### Test 2: Simulated Manual Delay
```powershell
"11\n" | .\run.bat
# Then manually type: 2<Enter>q<Enter>
```

**Expected Logs**:
- First input: +0.8s (automated)
- Second input: +5.0s [DELAY: MANUAL INPUT SUSPECTED]
- Third input: +3.0s [DELAY: MANUAL INPUT SUSPECTED]

### Test 3: Interactive Mode
```powershell
# Set default_mode=interactive in settings.ini
"q\n" | .\run.bat
```

**Expected Logs**:
- INTERACTIVE_WAIT_START/END pairs
- VK codes logged (38=Up, 40=Down, 13=Enter, 81=Q)
- Shift state tracked

## Implementation Notes

### Modified Files
1. **UI-Builder.ps1**: Added timing variables
2. **modules/logging/Logger.ps1**: Enhanced Log-Input, added Log-InputTiming
3. **modules/ui/MenuDisplay.ps1**: Added timing calls around all input operations

### Key Functions
- `Log-Input -Message "text" -Source "MenuType"`: Standard input logging with timing
- `Log-InputTiming -Action "WAIT_START" -Details "context"`: Event timing markers

### Best Practices
- Always call `Log-InputTiming` before blocking input operations
- Always call after input received
- Use descriptive Source names (NumberedMenu, InteractiveMenu, DescriptionBox)
- Check for >2s delays when reviewing logs
- Correlate input-timing.log with input.log for full picture

## Conclusion

This system provides **real-time visibility** into input operations, making it easy to:
- Identify where program waits for manual input during automated tests
- Detect performance bottlenecks in input handling
- Verify piped input is working correctly
- Debug interactive mode arrow key timing
- Confirm automated testing is truly automated (no manual intervention)

**Result**: User should NEVER need to manually type during AI testing. If timing logs show >2s delays, fix the input handling code.
