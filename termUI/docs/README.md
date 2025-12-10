# termUI v1.3.7 (consolidated guide)

PowerShell-driven terminal UI with a C# input handler (no stdin to PowerShell; all key events flow through the handler). Buttons are folder-discovered from `buttons/` (`.opt` files = options, folders = submenus, `.input` files = free-form input prompts). The smart `termUI.exe` launcher handles version display, update checks, and repair prompts.

## Status
- Production-ready; zero-crash test suite (10/10 scenarios, 467+ keypresses) and stress-tested navigation/input
- Auto-update/repair prompts built into `termUI.exe`; version source of truth is `VERSION.json`
- Current version: **1.3.7** (lastUpdated 2025-12-09)
- Self-bootstrap: exe-only copies can download and restore the full folder from GitHub before launch
- Identical behavior to `run.bat` with faster startup and built-in version/update/repair prompts.
- Self-repair/bootstrap triggers if core files are missing (modules/settings/buttons)

## Quick Start
- Launch: double-click `termUI.exe` (preferred) or `pwsh -ExecutionPolicy Bypass -File .\run.bat`
- Switches: `--version`, `--changelog`, `--check-update`, `--update`
- Navigation: Up/Down (wrap), Enter (select), Esc (back), Q (quit)

## Requirements
- Windows 10/11, PowerShell 5.0+
- .NET Framework present if you rebuild the input handler

## File Layout (clean structure)
```
termUI/
├── termUI.exe           # Smart launcher (update/repair/version)
├── run.bat              # Batch launcher
├── settings.ini         # Additive config (debug/logging/paths)
├── VERSION.json         # Canonical version + changelog
├── buttons/             # Menu tree (folders=submenus, .opt=options, .input=input prompts)
├── powershell/
│   ├── termUI.ps1       # UI loop + menu rendering
│   └── modules/         # Logging, settings, menu builder, input bridge, version manager
├── csharp/
│   ├── InputHandler.cs  # Key reader (C# 2.0)
│   └── compile_inputhandler.bat
├── _bin/_debug/         # Logs (rotated 5MB) + automated testing harness
└── _bin/ (optional)     # Archived utilities (version scripts, csharp, python) if present
```

## Build the input handler (optional)
```powershell
cd termUI/csharp
./compile_inputhandler.bat
```
Emits `bin/InputHandler.exe`; auto-locates `csc.exe` from installed .NET Frameworks.

## Configuration (`settings.ini` excerpt)
```ini
[General]
debug_mode=false
ui_title=termUI
menu_root=buttons\mainUI
keep_open_after_selection=true

[Updates]
check_on_startup=true
auto_install=false

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

## Navigation, Input, and Safety
- **Standard controls**: Up/Down wrap, Enter selects, Esc backs, Q quits.
- **Numbered selection + backspace**: Type digits (multi-digit allowed), see yellow buffer, Enter jumps; Backspace edits; Esc or arrows clear buffer; invalid indices clear safely.
- **Manual input detection (P key)**: In automated/test runs, pressing `P` logs a critical error, prints an unmissable red block explaining the blocked input, and exits with code 1. Use to flag any code path that waits for manual input (ReadKey/Read-Host without guards).
- **P key rules**: P = PROBLEM; only press when hung. Exit codes: 0 = normal, 1 = manual-input detected.

## Buttons and Input Buttons
- `.opt` name (minus extension) becomes the option label; empty files are fine. Folders become submenus.
- `.input` adds free-form input prompts. First line = prompt; remaining lines = description. Returns `{ name, path, value }` and works with capture mode.
- Example layout:
```
buttons/mainUI/
├── dashboard.opt
├── settings/
│   └── edit-settings.opt
└── TextInput/
  └── UserName.input   # prompt on line 1; optional description after
```

## Launcher: termUI.exe (native)
- C# launcher replaces legacy batch; passes args through to `powershell/termUI.ps1`, propagates exit codes, supports stdin redirection.
- Identical behavior to `run.bat` with faster startup and built-in version/update/repair prompts.

## Versioning and Auto-Update
- Semantic versioning (MAJOR.MINOR.PATCH); current `1.3.7`.
- Key files: `VERSION.json` (source of truth), `_debug/CURRENT_VERSION.txt` (auto marker, do not edit), `powershell/modules/VersionManager.ps1`, `VERSION_UPDATER.ps1`, `GitHub-VersionCheck.ps1`.
- Display info:
```powershell
cd termUI/powershell
. ./modules/VersionManager.ps1
Get-TermUIVersionString        # termUI v1.3.6 (2025-12-09)
Get-TermUIChangelog -EntryCount 5
```
- Update flow:
```powershell
cd termUI
./VERSION_UPDATER.ps1 -NewVersion "X.Y.Z" -Check
./VERSION_UPDATER.ps1 -NewVersion "X.Y.Z" -CurrentVersion "A.B.C" -Changes @("Change 1", "Change 2")
```
- GitHub workflow (summary): bump via updater → commit `VERSION.json` (and marker if tracking) → push → create GitHub release tag `vX.Y.Z`. Users run `./GitHub-VersionCheck.ps1` or `termUI.exe --check-update` / `--update` to compare/apply.

## GitHub Integration Quick Steps
1) Create release on https://github.com/SanitysHelper/cmd/releases/new (tag `vX.Y.Z`, title `termUI vX.Y.Z`).
2) Verify locally: `./GitHub-VersionCheck.ps1` (shows Local vs GitHub).
3) Routine before push: run `VERSION_UPDATER.ps1`, then `--version` and `--changelog` to confirm.

## Testing
- Interactive: `./run.bat` (or `termUI.exe`).
- Automated: `_debug/automated_testing_environment/` harness feeds events into `InputHandler.exe`; do not pipe directly into PowerShell.
- Covered scenarios: navigation wrap, deep menus, rapid spam, backspace buffer, input buttons, P-key failure path.

## Logging and Troubleshooting
- Logs in `_bin/_debug/logs/` with rotation at 5MB (important/error/input/input-timing/menu-frame/transcript).
- Launcher repair: if assets missing, it prompts to repair.
- Update failures: check internet/firewall; rerun `--check-update`.
- Blocked EXE: Properties → Unblock.

## Maintenance and Cleanup
- Clean structure keeps core in root; utilities may sit in `_bin/` (version scripts, csharp, python, debug tools). Use or copy from `_bin/` only as needed to keep root tidy.

## Development Snapshot
- Architecture: PowerShell UI + C# handler; menu discovery from folders; additive INI settings; six log types with rotation.
- Verified stability: 10/10 automated tests, rapid input stress, deep navigation.
- Known future ideas: description boxes, action handlers for `.opt`, search/filter, themes, capture-submenu shortcuts, metadata `.opt.meta`, validation for inputs.

## Support
- Repo: https://github.com/SanitysHelper/cmd
- This README supersedes other docs in `docs/`.

