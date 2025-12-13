# termUI & tagScanner Architecture Summary

## Core boot flow (termUI)
- `TermUILauncher.exe` -> runs `powershell/termUI.ps1` with args passthrough; auto-repair from GitHub if core files missing.
- `powershell/termUI.ps1` bootstraps: cleans temp updates, ensures required modules/settings, optional update check, loads settings (ini merged with defaults), and initializes menu tree from `buttons/mainUI`.
- Input handling: picks mode (test replay, piped stdin, interactive) via `InputHandler`/`InputBridge`; logs input/timing; supports capture/test modes.
- Menu rendering: tree built from filesystem (`MenuBuilder.ps1`) scanning folders + `.opt` descriptions + `.input` prompts; renders with ANSI clear; executes selected `.ps1` under menu root; rebuilds tree after execution.
- Logging/rotation: `Logging.ps1` writes error/important/input/input-timing/menu-frame/transcript with rotation limit; warns on manual-input delays.
- Refresh: `RefreshHelper.ps1` exposes `Invoke-TermUIMenuRefresh` calling `Force-MenuRefresh` to rebuild from disk.
- Button/Function helpers: `TermUIButtonLibrary.ps1` creates buttons programmatically; `TermUIFunctionLibrary.ps1` attaches script files in multiple languages and exposes `Refresh-TermUIMenu`.
- Updates: `Update-Manager.ps1` fetches GitHub zip, backs up (when debug_mode), installs via robocopy (excluding `_debug`, `_bin`, `buttons`, `.exe`), cleans temp; version info via `VersionManager.ps1`.

## Settings & config
- `settings.ini`: merged with defaults in `Settings.ps1`; sections General, Logging, Input. Key paths: `General.menu_root` (usually `buttons\mainUI`), `General.keep_open_after_selection`, `Logging.log_rotation_mb`.
- Paths used: `_bin/_debug/logs` for logs; `settings.ini` alongside exe; menu root at `buttons` folder sibling to `powershell`.

## Menu model
- Each folder is a submenu; `.opt` files define options with display name and optional description (numeric prefixes stripped). `.input` files define prompt + description for free-text input. Corresponding `.ps1` with same relative path runs on selection. Menu path uses `/` separators (e.g., `mainUI/Read Mode/Artist`).
- `InitializeButtons.ps1` (if present) runs before menu load and seeds default About/Test/Show Version buttons only when no buttons exist.

## Input modes
- **Interactive**: console keys via `[Console]::ReadKey` with safety fallbacks.
- **Piped**: uses `Host.UI.RawUI.KeyAvailable` when stdin redirected.
- **Test replay**: `InputHandler-Replay.ps1` outputs JSON events consumed by termUI loop; buffer-based event queue.
- **Test CLI overrides**: `--test-file <json>` auto-enables replay mode and uses `powershell/InputHandler-Replay.ps1` by default; `--test-handler <path>` or env `TERMUI_TEST_HANDLER` override the handler.
- **Capture**: optional args (`--capture-*`) save last selection/value to file.

## Logging highlights
- `input.log` includes delta seconds and delay tag if >2s to flag manual input.
- `menu-frame.log` captures each render (can be disabled via env `TERMUI_DISABLE_LOG_MENU_FRAME`).
- `important.log` records navigation/selection; `error.log` for failures; transcripts kept in `ui-transcript.log` and `output.log`.

## tagScanner program layer (termUIPrograms/tagScanner)
- Uses same launcher/termUI core copied into program folder.
- Buttons are now manual (auto initializer removed). Existing buttons under `buttons/mainUI`: Directories, Read Mode, Write Mode, Dependencies, Repair Metadata, plus extras submenus.
- Config: `config/directories.json` (seed list), `config/scan_directory.txt` (active working dir). Buttons in Directories write to scan_directory.txt for selection.
- Core module: `powershell/modules/TagScanner.ps1` handles dependency checks (local `_bin` first) for `metaflac.exe` and `TagLibSharp.dll`; provides Repair-Metadata (flac remove/reimport tags; mp3 TagLib save), Read/Write modes, tag-specific quick actions, description/comment helpers. Directory selection prefers scan_directory.txt; history file at `directory_history.txt`.
- Dependency buttons: Check/Auto Download/Manual; Auto Download pulls from Google Drive ids into `_bin` (always re-download, delete first). Paths now resolved relative to install (fixed hardcoded path in Repair Metadata button).
- Tests: `_tests` folder with JSON key sequences and runner `Run-Test.ps1` using termUI test mode. Prereqs: handler_path set to InputHandler-Replay; dependencies present; music directory populated.

## Extension points
- Add new programs: copy termUI core; place buttons under `buttons/mainUI`; write `.ps1` actions; optionally use `TermUIButtonLibrary`/`TermUIFunctionLibrary` for scripted generation; avoid overwriting `buttons` during updates.
- Dynamic menus: after creating/deleting buttons at runtime, call `Refresh-TermUIMenu` (or `Invoke-TermUIMenuRefresh`) to rebuild menu tree without restart.
- Settings tweaks: adjust `General.keep_open_after_selection`, enable/disable logging, change menu root.

## Maintenance risks / notes
- Avoid hardcoded absolute paths in button scripts; use relative resolution from `$PSScriptRoot`/parents.
- Keep `_bin` for program-local binaries; Update-Manager intentionally skips `buttons` to preserve program menus.
- If logs grow, `log_rotation_mb` controls rotation threshold; rotation applied per file.
- Ensure test mode env vars (`TERMUI_TEST_MODE=1`, `TERMUI_TEST_FILE=...`) when running replay tests.

## Minimal onboarding for another AI/maintainer
- Entry: run `termUI.exe` (or `powershell/termUI.ps1`) from termUI root; menu reads from `buttons/mainUI`.
- To add a button: create `buttons/mainUI/Folder/MyAction.opt` (description) and matching `MyAction.ps1` (logic). After adding during runtime, call `Refresh-TermUIMenu`.
- Logs: check `_bin/_debug/logs` for input/menu/error traces when diagnosing hangs or navigation issues.
- tagScanner: set working dir via Directories submenu (writes `config/scan_directory.txt`); dependencies belong in `_bin`.
