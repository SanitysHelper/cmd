# termUI Documentation (Consolidated)

This file consolidates prior Markdown content from `SMART_LAUNCHER_GUIDE.md` and `docs/README.md` into a single reference.

---

## From `SMART_LAUNCHER_GUIDE.md`

### termUI.exe - Smart Standalone Launcher

**Version**: Enhanced with Auto-Update Detection & Repair Checking  
**Date**: December 9, 2025  
**Size**: 8.7 KB (native executable)

#### Overview

The `termUI.exe` is a **smart, standalone launcher** that can be copied anywhere and will handle its own setup, update checking, and repair detection automatically.

#### ✅ YES - It Works Standalone!

You can copy **just `termUI.exe`** to any program folder and start building UIs with it. The launcher will:

1. ✅ **Check for missing files** - Detects if termUI installation is incomplete
2. ✅ **Check for updates** - Compares local version against GitHub
3. ✅ **Prompt for updates** - Notifies when newer version available
4. ✅ **Provide repair instructions** - Guides user if files are missing
5. ✅ **Launch termUI.ps1** - Starts the framework after all checks pass

---

#### Smart Features

##### 🔍 Auto-Detection
- `powershell/` directory existence
- `powershell/termUI.ps1` main script
- `VERSION.json` metadata file
- `settings.ini` configuration

##### 📦 Repair Detection
If any required files are missing, the launcher will show repair guidance and required structure. To repair: download full termUI from GitHub.

##### 🔄 Update Checking
1. Reads local `VERSION.json`
2. Fetches GitHub `VERSION.json`
3. Compares semantic versions
4. Displays update notification if newer version available

##### ⚡ Fast Startup
- Skips on no internet
- Launches immediately when up to date
- 5-second timeout so network never blocks startup

---

#### Usage Patterns
- **Copy to new program**: copy only `termUI.exe`, run, get repair guidance
- **Copy full folder**: copies everything, runs with update check
- **Drop exe into existing structure**: works immediately, checks updates

#### Command-Line Flags
Pass-through to `termUI.ps1`: `--version`, `--changelog`, `--check-update`, `--update`, capture flags, etc.

#### Required File Structure (minimal)
```
YourProgram/
├── termUI.exe
├── VERSION.json
├── settings.ini
├── powershell/
│   ├── termUI.ps1
│   └── modules/
└── buttons/
```

#### Building Your UI
Create `buttons/` tree with `.opt` and `.input` files; run `termUI.exe` to render.

#### Update Workflow
- Automatic check every launch (5s timeout)
- Manual: run `Update-Manager.ps1` or `termUI.exe --update`
- Dev: if local > GitHub, continues without prompt

#### Troubleshooting
Common issues: missing exe path, missing powershell dir, network failures. Works offline; skips update.

#### Technical Details
- C# launcher (.NET Framework 4.x), 8.7 KB
- Semantic versioning
- Network uses TLS 1.2, 5s timeout, silent fail

#### Summary
- Copy exe anywhere; auto-detects/repairs
- Checks updates; prompts when newer
- Fast startup; offline-safe; passes flags through

---

## From `docs/README.md`

### termUI v1.3.7 (consolidated guide)

PowerShell-driven terminal UI with a C# input handler. Buttons are folder-discovered from `buttons/` (`.opt` = options, folders = submenus, `.input` = prompts). `termUI.exe` handles version display, update checks, and repair prompts.

#### Status
- Production-ready; zero-crash test suite
- Auto-update/repair prompts built into `termUI.exe`; source of truth `VERSION.json`
- Current version in this guide: 1.3.7 (historical)
- Self-bootstrap for exe-only copies
- Matches `run.bat` behavior with faster startup

#### Quick Start
- Run `termUI.exe` (or `pwsh -ExecutionPolicy Bypass -File .\run.bat`)
- Switches: `--version`, `--changelog`, `--check-update`, `--update`
- Navigation: Up/Down, Enter, Esc, Q

#### Requirements
- Windows 10/11, PowerShell 5.0+
- .NET Framework installed if rebuilding input handler

#### Clean File Layout
```
termUI/
├── termUI.exe
├── run.bat
├── settings.ini
├── VERSION.json
├── buttons/
├── powershell/
│   ├── termUI.ps1
│   └── modules/
├── csharp/
│   ├── InputHandler.cs
│   └── compile_inputhandler.bat
├── _bin/_debug/
└── _bin/
```

#### Build Input Handler (optional)
```
cd termUI/csharp
./compile_inputhandler.bat
```

#### Configuration (excerpt)
INI settings for debug, updates, logging, input handler path.

#### Navigation, Input, Safety
- Standard controls; numbered selection; backspace editing
- P-key detection flags manual input waits; exits with code 1 in automation

#### Buttons & Input Buttons
- `.opt` name becomes label; folders = submenus
- `.input` files define prompt + description

#### Launcher: termUI.exe
- Pass-through args to PowerShell, propagates exit codes, supports stdin redirection

#### Versioning & Auto-Update
- Semantic versioning; `VERSION.json` is source of truth
- Helper scripts: `VersionManager.ps1`, `VERSION_UPDATER.ps1`, etc.

#### GitHub Integration (summary)
- Bump version, commit, push, release tag `vX.Y.Z`; users run `--check-update`

#### Testing
- Interactive via `run.bat`/`termUI.exe`
- Automated harness in `_debug/automated_testing_environment/`

#### Logging & Troubleshooting
- Logs in `_bin/_debug/logs/` (rotated)
- Repair prompts if assets missing; update failures often network/firewall

#### Maintenance
- Keep root clean; optional utilities under `_bin/`

#### Development Snapshot
- PowerShell UI + C# handler; folder-driven menus; additive INI; multiple logs

#### Support
- Repo: https://github.com/SanitysHelper/cmd
- This combined doc supersedes prior scattered docs in this folder.
