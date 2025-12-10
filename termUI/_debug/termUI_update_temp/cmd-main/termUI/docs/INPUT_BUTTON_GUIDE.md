# Input Button Type Guide

## Overview

The **input button** is a new button type in termUI that allows users to enter free-form text values without requiring pre-defined options. Instead of having a separate button for each possible value (like "A", "B", "C"), you can create a single input button that prompts the user and returns whatever they type.

## Creating an Input Button

### File Format

Create a `.input` file in your buttons directory:

```
buttons/mainUI/MyFeature/GetUserInput.input
```

### File Content Structure

The `.input` file contains:
- **Line 1**: The prompt text to display to the user
- **Lines 2+**: Description text (optional)

**Example:**

```
Enter your username:
This will be stored as the user's profile name
```

When selected, this shows: `Enter your username: _` and waits for user input.

## Button Behavior

### How It Works

1. User navigates menu and selects an input button
2. Program displays the prompt from line 1 of the `.input` file
3. User types any text (numbers, letters, special characters, etc.)
4. Value is captured and returned with metadata
5. Menu continues or exits (based on `keep_open_after_selection` setting)

### Return Value

When an input button is selected, the system returns a JSON object with:

```json
{
  "name": "GetUserInput",
  "path": "mainUI/MyFeature/GetUserInput",
  "value": "whatever_the_user_typed"
}
```

This is the same format as option buttons, with the addition of the `value` field containing the user's input.

### Capture Mode

Input buttons work seamlessly with termUI's capture mode:

```powershell
.\run.bat --capture-file result.json --capture-path mainUI/MyFeature
# User selects input button and enters: "test_value"
# result.json contains: { "name": "GetUserInput", "path": "...", "value": "test_value" }
```

## Visual Display

In the menu, input buttons appear as:

```
=== termUI v1.1.0 ===
Path: mainUI/TextInput

 1 (input) UserName
 2 (input) CustomValue

[Up/Down] Navigate  [#] Quick Select  [Escape] Back  [Q] Quit
```

When selected, the user sees:

```
========================================
 INPUT: UserName
 Value: john_doe
 Path: mainUI/TextInput/UserName
========================================
```

## Use Cases

### 1. User Configuration
```
buttons/mainUI/Settings/SetUsername.input
```
Content:
```
Enter your username:
Choose any username for your profile
```

### 2. Data Entry
```
buttons/mainUI/Tools/EnterValue.input
```
Content:
```
Enter numeric value:
Type any number (integers or decimals accepted)
```

### 3. Custom Text
```
buttons/mainUI/Tools/WriteNote.input
```
Content:
```
Enter your note:
Type any text. Press Enter when done.
```

## Technical Details

### File Naming
- Use descriptive names: `GetUsername.input`, `EnterEmail.input`
- Avoid spaces; use camelCase or underscores
- The button label will be the filename without extension

### Prompt Text
- Keep prompts short and clear
- First line is always the prompt
- Multi-line descriptions appear in the "Description" field when hovering

### Data Types
The input system accepts **any text that can be typed on the keyboard**:
- Text: `john`, `example@email.com`, `hello world`
- Numbers: `123`, `45.67`, `-99`
- Special characters: `!@#$%^&*()`
- Mixed: `user@domain_123`

**Note**: PowerShell treats all input as strings. If you need type conversion, handle it in your downstream script.

### Logging

Input selections are logged:

```
[2025-12-08 22:44:50] INFO: Input button 'UserName' received: john_doe
```

And captured in transcripts:

```
[2025-12-08 22:44:50] INPUT TRANSCRIPT: Input button: mainUI/TextInput/UserName = john_doe
```

## Comparison: Input Button vs Option Buttons

### Without Input Button (Old Way)
```
buttons/mainUI/Calculator/Value/
├── 0.opt
├── 1.opt
├── 2.opt
├── 3.opt
... (10+ files for digits)
```
Menu shows 10+ individual buttons. User clicks one.

### With Input Button (New Way)
```
buttons/mainUI/Calculator/
└── EnterValue.input
```
Menu shows 1 input button. User types the value directly.

**Result**: Cleaner menus, more flexible, less file clutter.

## Examples

### Example 1: Name Input
```
File: buttons/mainUI/Profile/EnterName.input

Content:
What is your name?
Enter your full name here. You can change it later.
```

Usage flow:
```
1. Navigate to Profile menu
2. Select "EnterName" option
3. Terminal shows: "What is your name?: "
4. User types: "Alice Smith"
5. Result: { "name": "EnterName", "path": "mainUI/Profile/EnterName", "value": "Alice Smith" }
```

### Example 2: Email Input
```
File: buttons/mainUI/Account/SetEmail.input

Content:
Enter email address:
This will be used for notifications and password recovery
```

### Example 3: Configuration Value
```
File: buttons/mainUI/Settings/MaxRetries.input

Content:
Enter maximum number of retries:
How many times should the system retry on failure? (default: 3)
```

## Implementation Notes

### How Input Buttons Are Processed

1. **MenuBuilder** (`MenuBuilder.ps1`):
   - Scans directories for `.input` files
   - Reads first line as prompt text
   - Reads remaining lines as description
   - Creates menu item with `Type: "input"`

2. **termUI** (`termUI.ps1`):
   - Detects `$item.Type -eq "input"`
   - Displays prompt using `Read-Host`
   - Captures the returned value
   - Returns JSON with name, path, and value
   - Logs to important.log for audit trail

3. **Capture Mode**:
   - If `--capture-file` specified, saves the JSON result
   - Result includes the user's entered value
   - Accessible to parent processes or scripts

## Troubleshooting

### Issue: Input button doesn't show up
**Solution**: Ensure file has `.input` extension (not `.opt`)

### Issue: Prompt text is wrong
**Solution**: First line of `.input` file is the prompt. Make sure it's on line 1.

### Issue: Special characters in input aren't captured
**Solution**: They should be! If having issues, check your downstream script's encoding (use UTF-8)

### Issue: Empty input crashes the program
**Solution**: Program accepts empty input. If you need validation, add it in a downstream script.

## Future Enhancements

Possible improvements:
- Input validation (regex patterns in `.input` file)
- Input type hints (password input, numeric only, email format, etc.)
- Character limits
- Default values
- Multi-line input prompts
- Dropdown suggestions

