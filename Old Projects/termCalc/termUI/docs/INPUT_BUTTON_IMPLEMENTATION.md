# Input Button Type - Implementation Complete

## What Was Added

A new button type called **"input"** that allows users to enter any free-form text without requiring pre-defined option buttons.

## Key Features

### 1. Simple Creation
Create a `.input` file in your buttons directory:

```
buttons/mainUI/MySection/GetInput.input
```

Content (first line is the prompt):
```
What is your name?
This will be saved to your profile
```

### 2. Flexible Data Types
Users can enter:
- Text: `hello`, `john_doe`, `example@email.com`
- Numbers: `123`, `45.67`, `-99`
- Special characters: `!@#$%^&*()`
- Any keyboard input

### 3. Captured Return Value
When selected, returns:
```json
{
  "name": "GetInput",
  "path": "mainUI/MySection/GetInput",
  "value": "user_entered_text_here"
}
```

### 4. Seamless Integration
- Works with capture mode (`--capture-file`)
- Logs to important.log for audit trail
- Displays in menu as `(input)` type
- Consistent with existing option button workflow

## Files Modified

### Core System
1. **MenuBuilder.ps1** - Added `.input` file scanning and parsing
2. **termUI.ps1** - Added input button handling and prompt display

### Documentation
3. **INPUT_BUTTON_GUIDE.md** - Comprehensive guide with examples

### Examples
4. **buttons/mainUI/TextInput/UserName.input**
5. **buttons/mainUI/TextInput/CustomValue.input**
6. **buttons/mainUI/TextInput/NumberA.input**
7. **buttons/mainUI/TextInput/NumberB.input**

## Use Cases

### Before (No Input Buttons)
```
buttons/mainUI/Numbers/
├── 0.opt
├── 1.opt
├── 2.opt
├── 3.opt
... (many more)
```
Menu cluttered with 10+ buttons for similar input

### After (With Input Buttons)
```
buttons/mainUI/Numbers/
└── EnterNumber.input
```
Single button. User types any value directly.

## Menu Display

When visiting the TextInput example menu:

```
=== termUI v1.1.0 ===
Path: mainUI/TextInput

 1 (input) UserName
 2 (input) CustomValue
 3 (input) NumberA
 4 (input) NumberB

Description: This will prompt you to enter any text value and return it
[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit
```

## Workflow Example

1. User navigates to TextInput menu
2. Selects "UserName" option
3. Terminal prompts: `Enter your name: `
4. User types: `Alice`
5. Program displays selection confirmation
6. Result saved: `{ "name": "UserName", "path": "mainUI/TextInput/UserName", "value": "Alice" }`

## Benefits

✅ **Eliminates menu clutter** - One button instead of 10+
✅ **Flexible data entry** - Any text can be entered
✅ **No pre-configuration** - Don't need to create a button for each possible value
✅ **Consistent interface** - Works like regular option buttons
✅ **Full logging** - All entries are logged for audit trail
✅ **Easy integration** - Works with existing capture mode and workflows

## Next Steps

1. Create your own `.input` files in your menu structure
2. Follow the format: first line = prompt, remaining = description
3. Users will see them as `(input)` type buttons in the menu
4. Captured values include the user's exact input
5. No additional setup required!

## Technical Architecture

### File Detection
- `MenuBuilder.ps1` scans for `*.input` files using `Get-ChildItem -Filter "*.input"`
- Each file becomes a menu item with `Type: "input"`

### Prompt Processing
- First line of `.input` file is extracted as the prompt
- Remaining lines become the description

### Input Handling
- `termUI.ps1` detects `$item.Type -eq "input"`
- Calls `Read-Host -Prompt $item.Prompt`
- Captures return value and wraps in JSON object

### Output Format
- Compatible with existing capture mode
- Includes metadata (name, path, value)
- Logged to important.log automatically

## All Copies Synchronized

✓ cmd/termUI/
✓ termCalc/termUI/
✓ cmdBrowser/termUI/

All three termUI instances now support input buttons with identical behavior.

---

**Status**: ✅ COMPLETE AND TESTED
**Version**: 1.1.0+
**Integration**: Full menu system, capture mode, logging
