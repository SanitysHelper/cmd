# termUI - Numbered Selection with Backspace Feature
# Manual Testing Guide

## Features Implemented

### 1. Numbered Selection
- Type any number (0-9) to build a number string
- Numbers appear in yellow at bottom: "Input: 5"
- Press Enter to jump to that numbered item
- Example: Type "2" then Enter to select item [2]

### 2. Multi-Digit Support
- Type "10" then Enter to select item [10]
- Type "23" then Enter to select item [23]
- Works with any valid item count

### 3. Backspace Support
- Press Backspace to delete the last digit
- Example: Type "123" then Backspace → "12"
- Backspace again → "1"
- Clear buffer completely by backspacing all digits

### 4. Buffer Management
- Escape key clears the input buffer (shows cleared input)
- Arrow keys (Up/Down) automatically clear buffer before navigation
- Invalid numbers (e.g., "99" with only 6 items) are ignored, buffer clears
- Buffer clears after successful selection

## How to Test Manually

### Test 1: Basic Numbered Selection
1. Run: `.\run.bat`
2. Type: `2`  
   → See "Input: 2" in yellow at bottom
3. Press: Enter
   → Should enter "help" submenu (item [2])
4. Press: Escape
   → Return to main menu

### Test 2: Multi-Digit Numbers
1. From main menu, type: `6`
2. See: "Input: 6" in yellow
3. Press: Enter  
   → Should select "home" (item [6])
4. Press: Any key to continue
5. Type: `1` (now on main menu again)
6. See: "Input: 1"
7. Type: `0` while buffer shows "1"
   → Should see "Input: 10" in yellow
8. Press: Enter
   → Buffer clears (invalid item count)
   → Menu re-renders

### Test 3: Backspace Functionality
1. Type: `5`
   → See "Input: 5"
2. Press: Backspace
   → See "Input: " (empty, but still yellow)
3. Type: `2`
   → See "Input: 2"
4. Type: `3`  
   → See "Input: 23"
5. Press: Backspace
   → See "Input: 2"
6. Press: Backspace
   → See "Input: " (empty)
7. Press: Backspace (empty buffer)
   → Nothing happens (safe - no error)

### Test 4: Escape Clears Buffer
1. Type: `1`
   → See "Input: 1"
2. Type: `2`
   → See "Input: 12"
3. Press: Escape
   → Input buffer cleared
   → Back to normal controls display
   → Selection remains on current item (doesn't go back submenu at root)

### Test 5: Arrow Keys Clear Buffer
1. Type: `3`
   → See "Input: 3"
2. Press: Up Arrow
   → Input buffer cleared
   → Selection moves up
   → Menu re-renders

### Test 6: Invalid Number Handling
1. Type: `1` (main menu has only 6 items)
2. Type: `0` → "Input: 10"
3. Press: Enter
   → Number 10 is invalid (max: 6)
   → Buffer automatically clears
   → Menu re-renders without exiting
   → Selection stays on current item

## Control Display Changes

When buffer is empty (normal mode):
```
[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit
```

When buffer has input:
```
[Up/Down] Navigate  [#] Quick Select  [Backspace] Delete  [Escape] Back  [Q] Quit  |  Input: 5
```

Notice:
- Backspace option only shows when buffer is active
- Input value shown in yellow for visibility
- All other controls remain available

## Code Implementation Summary

### Changes Made to termUI.ps1:

1. **Input Buffer Variable** (line 88):
   - `$numberBuffer = ""` - tracks typed digits

2. **Render-Menu Function** (line 95-115):
   - Added `$InputBuffer` parameter
   - Updated display to show buffer in yellow when active
   - Shows Backspace hint when buffer has content

3. **Digit Handling** (lines 237-244):
   - Char event handler checks for digits [0-9]
   - Appends to `$numberBuffer`
   - Triggers re-render to show input

4. **Backspace Handler** (lines 245-252):
   - New case for Backspace key
   - Removes last character from buffer
   - Re-renders to show updated input

5. **Enter Key Processing** (lines 254-275):
   - Checks if numberBuffer is not empty
   - Converts to integer index (1-based to 0-based)
   - Validates index against item count
   - Selects item if valid, clears buffer if invalid

6. **Navigation Clearing** (lines 277-291):
   - Up/Down arrow handlers clear buffer
   - Escape handler clears buffer if present

## User Experience

### Positive Aspects:
- Natural number entry like menu-driven UIs
- Visual feedback with yellow highlighting
- Safety: invalid numbers don't cause errors
- Backspace support for corrections
- Non-intrusive: works alongside existing navigation

### Edge Cases Handled:
- Typing when buffer empty works correctly
- Backspacing when buffer empty is safe (no-op)
- Multi-digit numbers supported
- Buffer persists through re-renders
- Invalid selections don't crash program

## Integration Notes

This feature extends the existing keyboard input system:
- Works with both interactive and test modes
- Plays nicely with arrow key navigation
- Q key for quit still functions normally
- Escape for back/clearing works as expected
- All existing features (submenu entry, options) unchanged
