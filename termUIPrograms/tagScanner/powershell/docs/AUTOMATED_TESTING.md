# termUI Automated Testing Guide

This guide explains how to run and author automated UI tests for termUI and termUI-based programs (e.g., tagScanner). It covers prerequisites, settings, CLI flags, writing replay files, and verifying results.

## Core concepts
- termUI supports replay-driven input via JSON event files consumed by an input handler.
- The default replay handler is powershell/InputHandler-Replay.ps1.
- Test mode is activated by environment variables or CLI flags; in test mode, termUI pre-buffers all events and never blocks for manual input.
- Logs and transcripts are written under _bin/_debug/logs for inspection.

## Required settings (settings.ini)
- Input handler: [Input.handler_path] should point to powershell/InputHandler-Replay.ps1 (default is already set).
- Keep-open behavior: [General.keep_open_after_selection] controls whether termUI exits after executing a button (default true). For automated tests, either leave true or use capture mode if you need post-run artifacts.
- Show selected prompt: [General.show_selected_prompt] can be enabled to make selections visible in logs.

Example settings used for recent tests (current repo):
```
[Input]
handler_path=powershell\InputHandler-Replay.ps1
```

## CLI flags for test mode
- --test-file <path> : Enables test mode and points to a JSON event file.
- --test-handler <path> : Override the replay handler (optional). If omitted, uses handler_path from settings or the default.
- Capture mode (optional):
  - --capture-file <path>
  - --capture-once (quit after one selection)
  - --capture-path <menuPath>
  - --capture-auto-index <n> or --capture-auto-name <Name>

Example run from termUI root:
```
powershell -NoProfile -ExecutionPolicy Bypass -File powershell\termUI.ps1 --test-file _debug\test_basic.json
```

## Event file format
A test file is an array of key events. Supported keys include Enter, Up, Down, Escape, Q, Backspace, and Char (with a "char" property). Example minimal smoke test:
```
[
  { "key": "Enter" },
  { "key": "Q" }
]
```
This selects the first menu item, runs it, then quits.

## Logs to check
- input.log: sequence of key events with timestamps.
- input-timing.log: deltas between events (helps catch manual waits).
- important.log: navigation and selections.
- output.log: full transcript of console output for the session.
- error.log: any failures.
- menu-frame.log: only if [Logging.log_menu_frame]=true (disabled in current settings).

Logs live at _bin/_debug/logs under the running program (global termUI or program-local copy).

## Running tests for termUI (global copy)
1) Ensure settings.ini has a valid handler_path (already set by default).
2) From termUI root, run:
```
powershell -NoProfile -ExecutionPolicy Bypass -File powershell\termUI.ps1 --test-file _debug\test_basic.json
```
3) Review _bin/_debug/logs/output.log and important.log to confirm expected navigation.

## Running tests for tagScanner (program copy)
1) Ensure termUIPrograms/tagScanner/settings.ini points handler_path to powershell/InputHandler-Replay.ps1.
2) From termUIPrograms/tagScanner, run:
```
powershell -NoProfile -ExecutionPolicy Bypass -File .\_tests\Run-Test.ps1 -TestFile test_read_notes.json
```
- Run-Test.ps1 sets TERMUI_TEST_MODE/TERMUI_TEST_FILE and launches tagScanner via powershell/termUI.ps1.
- Verify results in _bin/_debug/logs/output.log and important.log.

## Authoring new replay tests
1) Create a JSON file in the program’s _tests/ folder describing the key sequence (use Enter/Up/Down/Char etc.).
2) If the test requires text input, emit a sequence of Char events followed by Enter.
3) Add the new file to version control and, optionally, document it in _tests/README.md.
4) Run with Run-Test.ps1 (program) or termUI --test-file (global) as shown above.

## Handling blocking prompts
- In test mode, default buttons skip Read-Host pauses (About/Test). When writing new scripts, gate pauses with `$env:TERMUI_TEST_MODE -ne "1"` to avoid hangs.

## Troubleshooting checklist
- "Test file not found": confirm the path exists and is passed to --test-file or Run-Test.ps1.
- "handler missing": ensure powershell/InputHandler-Replay.ps1 exists and handler_path points to it.
- menu-frame.log still grows when disabled: verify [Logging.log_menu_frame]=false and re-run; timestamp should stop changing.
- Update check noise during tests: set [Updates.check_on_startup]=false to skip network calls in CI.
- Path issues: always run from the program root so relative paths (settings, buttons, logs) resolve correctly.

## Quick references
- Default replay handler: termUI/powershell/InputHandler-Replay.ps1
- Sample replay: termUI/_debug/test_basic.json
- tagScanner runner: termUIPrograms/tagScanner/_tests/Run-Test.ps1
- Logs location: <program>/_bin/_debug/logs
