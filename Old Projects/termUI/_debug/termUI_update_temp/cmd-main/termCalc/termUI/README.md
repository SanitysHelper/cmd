# termUI (interactive terminal UI)

Minimal interactive menu shell with a C# input handler. UI rendering and menu logic live in PowerShell; key events flow from the C# handler only (no direct stdin to PowerShell). Buttons are discovered from the `buttons/` folder (folders = submenus, `.opt` files = options) rooted at `mainUI`.

## ✅ Current Status

**All Systems Operational - Fully Tested & Stable**

**Working:**
- ✅ Folder structure organized by language (powershell/, csharp/, python/)
- ✅ C# InputHandler compiles successfully (C# 2.0 compatible with .NET Framework 2.0)
- ✅ PowerShell UI loads and displays menu correctly
- ✅ Menu tree built from buttons/ folder structure (dynamic discovery)
- ✅ Settings system with additive/tolerant INI loading (new keys won't break code)
- ✅ Logging system (important, error, input, input-timing, menu-frame, transcript) with 5MB rotation
- ✅ Interactive menu rendering with numbered options and color highlighting
- ✅ Navigation: Up/Down with wrap-around, Enter to select, Escape to back, Q to quit
- ✅ Deep submenu navigation (tested 3+ levels)
- ✅ Bounds checking and array safety
- ✅ Unique key event IDs with timestamps for debugging
- ✅ Test mode for automated testing (10 test scenarios)
- ✅ Stress tested: 200+ rapid keypresses, spam keys, edge cases
- ✅ Sample menu structure: 8 options across 4 submenus

**Test Results:**
- Basic Navigation: ✅ PASS
- Spam Down (50x): ✅ PASS
- Spam Up (50x): ✅ PASS
- Deep Navigation: ✅ PASS
- Rapid Alternating (60x): ✅ PASS
- Spam Enter (20x): ✅ PASS
- Spam Escape (20x): ✅ PASS
- Navigate All Options: ✅ PASS
- Extreme Edge Cases: ✅ PASS
- Insane Stress (200x): ✅ PASS

**10/10 Tests Passed - Zero Crashes**

## Structure
```
termUI/
├── run.bat                          # Entry point (launches PowerShell UI)
├── settings.ini                     # Additive settings (debug, logging, paths)
├── README.md                        # This file
├── powershell/
│   ├── termUI.ps1                  # Main orchestrator & UI loop
│   └── modules/
│       ├── Logging.ps1             # Centralized logging with rotation
│       ├── Settings.ps1            # Tolerant INI loader & defaults
│       ├── MenuBuilder.ps1         # Build tree from buttons/ folder
│       └── InputBridge.ps1         # Launch & communicate with InputHandler
├── csharp/
│   ├── InputHandler.cs             # Console input handler (C# 2.0 compatible)
│   ├── compile_inputhandler.bat    # Auto-find csc.exe and compile
│   └── bin/
│       └── InputHandler.exe        # Compiled handler
├── buttons/
│   └── mainUI/                     # Root menu path
│       ├── dashboard.opt           # Leaf option (empty file)
│       └── settings/               # Submenu folder
│           └── edit-settings.opt   # Nested option
├── python/                          # Reserved for future use
└── _debug/
    ├── logs/                       # All log files (auto-created)
    ├── automated_testing_environment/
    └── test_ui.ps1                 # Test harness (WIP)
```

## Build the input handler
Run from `termUI/csharp`:
```powershell
.\compile_inputhandler.bat
```
This emits `bin/InputHandler.exe`. The script auto-detects csc.exe from .NET Framework directories.

## Running the UI

**Interactive mode** (for manual testing):
```powershell
cd termUI
.\run.bat
```
Use arrow keys to navigate, Enter to select, Escape to go back, Q to quit.

**Test mode** (automated testing):
```powershell
cd _debug
.\run_all_tests.ps1  # Run complete test suite
.\run_test.ps1 test1_basic.txt  # Run specific test
```

**Test Suite:**
- `test1_basic.txt` - Basic navigation (Down, Up, Enter, Escape, Quit)
- `test2_spam_down.txt` - Spam Down key 50x (wrap-around test)
- `test3_spam_up.txt` - Spam Up key 50x (wrap-around test)
- `test4_deep_nav.txt` - Deep submenu navigation
- `test5_alternating.txt` - Rapid Up/Down alternating 60x
- `test6_spam_enter.txt` - Spam Enter 20x (selection stress)
- `test7_spam_escape.txt` - Spam Escape 20x (back navigation)
- `test8_all_options.txt` - Visit every menu option
- `test9_extreme.txt` - Edge cases and invalid keys
- `test_insane.txt` - 200 rapid keypresses (stress test)

## Testing (automated environment)
Use `_debug/automated_testing_environment/` to run tests. Drive the UI by feeding events into `InputHandler.exe`; do not pipe input to PowerShell.

## Buttons
Place submenus as folders under `buttons/mainUI/`. Each selectable option is a `.opt` file; filename becomes the option label (minus extension). Empty files are OK; the UI only reads structure for building menus.

Example:
```
buttons/mainUI/
├── dashboard.opt        # Root-level option
└── settings/            # Submenu
    └── edit.opt         # Nested option (path: mainUI/settings/edit)
```

## Settings (settings.ini)

All settings are additive; new keys won't break existing code. Defaults are defined in `powershell/modules/Settings.ps1`.

```ini
[General]
debug_mode=false
ui_title=termUI
menu_root=buttons\mainUI
keep_open_after_selection=true

[Logging]
log_input=true
log_input_timing=true
log_error=true
log_important=true
log_menu_frame=true
log_transcript=true
log_rotation_mb=5

[Input]
handler_path=csharp\bin\InputHandler.exe
```

## Next Steps

**Phase 1 Complete ✅** - Core UI and navigation fully functional

**Future Enhancements:**
1. Add action handlers for .opt file execution (launch programs/scripts)
2. Implement description boxes (Shift+Enter pattern)
3. Add configuration editor within UI
4. Support for colored themes
5. History tracking (last selected option)
6. Search/filter functionality for large menus

