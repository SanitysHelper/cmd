# tagScanner Automated Testing

## Overview

This directory contains automated UI tests for tagScanner using termUI's test mode infrastructure.

## How It Works

1. **Test Input Files** (JSON): Define sequences of key presses to simulate user interaction
2. **Input Handler**: Plays back the JSON events to termUI
3. **Test Runner**: Launches termUI in test mode with environment variables set
4. **Output Verification**: Checks logs for expected results (optional)

## Running Tests

```powershell
# Run a specific test
.\Run-Test.ps1 -TestFile test_read_artist.json

# Run with output verification
.\Run-Test.ps1 -TestFile test_read_artist.json -Verify
```

## Test Input Format

Each test file is a JSON array of input events:

```json
[
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Escape"},
  {"key": "Q"}
]
```

### Supported Keys

- **Navigation**: `Up`, `Down`, `Left`, `Right`
- **Action**: `Enter`, `Escape`, `Tab`, `Backspace`
- **Quit**: `Q`
- **Characters**: `{"key": "Char", "char": "1"}` for numbers/letters

## Creating New Tests

1. Create a new JSON file in `_tests/` directory
2. Define the key sequence needed to test your scenario
3. Run the test: `.\Run-Test.ps1 -TestFile your_test.json`

### Example: Test Reading Album Tags

```json
[
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Escape"},
  {"key": "Down"},
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Q"}
]
```

## Test Files

- `test_read_artist.json` - Navigate to Directories → Music → Read Mode → Artist
- `test_read_notes.json`  - Navigate to Read Mode → Comment (combined: FLAC Description, MP3 Comment)

## Prerequisites

1. `C:\Users\cmand\Music` directory must exist with FLAC/MP3 files
2. tagScanner dependencies (metaflac.exe, TagLibSharp.dll) must be installed
3. termUI must be configured with `handler_path=powershell\InputHandler-Replay.ps1` in settings.ini

## Output

Test results are logged to:
- `_bin\_debug\logs\output.log` - Complete terminal transcript
- `_bin\_debug\logs\ui-transcript.log` - UI interaction log

## Troubleshooting

**Test hangs or doesn't complete:**
- Check that the key sequence matches the actual menu structure
- Verify the working directory is set correctly (`C:\Users\cmand\Music`)
- Check output.log for errors

**No output in logs:**
- Ensure test mode environment variables are set correctly
- Verify InputHandler-Replay.ps1 exists in termUI/powershell/

**Tests fail with dependency errors:**
- Run Dependencies → Check Dependencies manually first
- Place metaflac.exe and TagLibSharp.dll in `_bin/` directory
