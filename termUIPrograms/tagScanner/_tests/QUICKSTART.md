# tagScanner Automated Testing - Quick Start

## Summary

I've set up a complete automated UI testing infrastructure for tagScanner (and any termUI program). Here's what was created:

## Files Created

1. **Input Handler** (`termUI/powershell/InputHandler-Replay.ps1`)
   - Replays JSON input sequences to termUI
   - Simple PowerShell script that reads JSON and outputs events

2. **Test Runner** (`termUIPrograms/tagScanner/_tests/Run-Test.ps1`)
   - Launches termUI in test mode
   - Sets environment variables (TERMUI_TEST_MODE=1, TERMUI_TEST_FILE)
   - Captures output and provides verification

3. **Test Input Files** (in `_tests/`):
   - `test_read_artist.json` - Test reading Artist tags
   - `test_read_album.json` - Test reading Album tags
   - `test_write_artist.json` - Test writing Artist tags

4. **Configuration** (`termUI/settings.ini`)
   - Added `handler_path=powershell\InputHandler-Replay.ps1` to [Input] section

5. **Documentation** (`_tests/README.md`)
   - Complete guide on creating and running tests

## How to Run a Test

```powershell
cd C:\Users\cmand\OneDrive\Desktop\cmd\termUIPrograms\tagScanner\_tests
.\Run-Test.ps1 -TestFile test_read_artist.json
```

## Test Sequence Explanation

For `test_read_artist.json`:
1. Press Down → Navigate to Directories
2. Press Enter → Enter Directories submenu
3. Press Down → Skip "Add Directory", land on "C:\Users\cmand\Music"
4. Press Enter → Select that directory
5. Press Escape → Go back to main menu
6. Press Down → Skip Directories
7. Press Down → Navigate to Read Mode
8. Press Enter → Enter Read Mode submenu
9. Press Enter → Select "Artist" (first option)
10. Press Q → Quit after viewing results

## Output

Results are logged to:
- `_bin\_debug\logs\output.log` - Full terminal output including tag data
- `_bin\_debug\logs\ui-transcript.log` - UI interaction log

## Creating New Tests

1. Map out the menu navigation manually
2. Create a JSON file with the key sequence:
```json
[
  {"key": "Down"},
  {"key": "Enter"},
  {"key": "Q"}
]
```
3. Run: `.\Run-Test.ps1 -TestFile your_test.json`

## Verification

Add `-Verify` flag to check output:
```powershell
.\Run-Test.ps1 -TestFile test_read_artist.json -Verify
```

This will check if expected tag data appears in the output log.

## Benefits

- ✅ Automated regression testing for UI workflows
- ✅ Verify FLAC/MP3 tag operations work correctly
- ✅ Test different menu paths without manual clicking
- ✅ Capture full output for debugging
- ✅ Reproducible test scenarios
- ✅ Works for any termUI program (not just tagScanner)

## Next Steps

1. Ensure `C:\Users\cmand\Music` has FLAC files with tags
2. Run the test: `.\Run-Test.ps1`
3. Check output.log to see tag data
4. Create more test scenarios as needed

## Extending to Other Programs

The same infrastructure works for ANY termUI program:

1. Create a `_tests/` folder in your program directory
2. Copy `Run-Test.ps1` and adapt the paths
3. Create JSON test sequences for your program's menus
4. Run tests the same way

The global `InputHandler-Replay.ps1` is reusable across all programs.
