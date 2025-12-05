# Copilot Instructions for cmd Workspace

## Project Overview

A collection of Windows batch/PowerShell automation tools orchestrating system tasks through a **dual-dispatch pattern**: root-level launcher scripts check `status.txt`, then spawn parallel task modules.

## Architecture

### Pattern: Status-Gated Parallel Dispatch
- **Root launchers** (`executeforMusic.bat`, `tagScanner.bat`): Check `status.txt` in target folder for `"false"` to gate execution
- **Task modules** (directories): Contain `status.txt`, `run.bat` (or `.ps1`), and `_temp_locks/` for synchronization
- **Lock files** (`_temp_locks/*.lock`): Temp sentinel files that are deleted on task completion; launcher waits until all locks are gone

### Key Modules

1. **updatingExecutor** - Clipboard-to-script runner
   - Reads clipboard content, strips BOM, offers R/V/E/Q menu
   - Executes user batch scripts in isolated `run_space/` workspace
   - Uses `read_clip.ps1` (inline-generated PowerShell) to handle clipboard safely

2. **tagScanner** - Unified FLAC/MP3 metadata editor
   - `Read-Comments.ps1`: Auto-detects metaflac.exe and TagLib# (taglib-sharp.dll)
   - Reads stored directories from `enteredDirectories.txt`
   - Debug mode controlled via `settings.txt` (debug=true/false)

3. **codeFetcher** - Directory content dumper
   - Menu-driven directory selection (persists in `dumpDirectories.txt`)
   - Outputs file tree to `dump_output.txt`

4. **dirWatcher** - File change monitor
   - Watches directories (stored in `watchDirectories.txt`)
   - Applies batch scripts to matching files (stored in `watchTargets.txt`)
   - Detects new/modified files and triggers actions

5. **executeforMusic** - Music sync orchestrator
   - `syncMusicDr.bat`: robocopy from Drive→Local
   - `syncMusicPlr.bat`: Player-specific sync logic

6. **killprocess** - Process terminator
   - Reads process names from clipboard
   - Clipboard interaction follows updatingExecutor pattern

## Critical Patterns

### Encoding & BOM Handling
- **Strip BOM**: Use `Get-Clipboard` + trim `[char]0xFEFF` when reading from clipboard
- **Write ASCII/UTF8**: Avoid Set-Content BOM by using `-Encoding ASCII` or piping via `more` to strip spurious BOMs
- **Example** (`updatingExecutor\run.bat`, lines 25-35): Inline PowerShell generation with explicit ASCII encoding

### Stored Directory Pattern
- Modules persist user selections across runs
- **Naming convention**: `*Directories.txt` (singular or plural), `watchTargets.txt`
- Files are plain text, one path/entry per line
- Modules validate existence and offer creation if missing

### Run Spaces
- **Location**: `module/run_space/` folder (created if missing)
- **Purpose**: Isolated execution context to avoid pollution
- **Contents**: Temp files (`clip_input.txt`, `*.tmp`), compiled helpers (`read_clip.ps1`), output artifacts
- **Cleanup**: Scripts delete `*.tmp` on exit; lock files cleaned by parent

### Debug Mode via Settings File
- **Pattern**: `settings.txt` with key=value pairs (e.g., `debug=true`)
- **Example** (`tagScanner\Read-Comments.ps1`, lines 20-42): Parse settings, conditionally enable verbose output
- Store settings in module root, not run_space

## Developer Workflows

### Running a Launcher
```batch
cd c:\Users\cmand\OneDrive\Desktop\cmd
executeforMusic.bat  :: Checks status.txt, launches tasks in parallel
```

### Parallel Execution Sync
1. Launcher creates `_temp_locks/` if missing
2. For each target script, creates `taskname.bat.lock`
3. Starts each script in new window with: `call script.bat & del lockfile`
4. Launcher waits in loop checking `dir _temp_locks\*.lock` (when count=0, all done)

### Adding a New Module
1. Create folder: `newModule/`
2. Add: `status.txt` (containing "true" or "false")
3. Add: `run.bat` (or `.ps1` wrapped by `run.bat`)
4. Add: `_temp_locks/` (empty folder)
5. (Optional) Add: `settings.txt` if debug/config needed
6. Update root launcher to include or document

### Clipboard Interaction
- **Read clipboard safely**: Use inline PowerShell `Get-Clipboard -Raw` + BOM strip
- **Error codes**: 0=success, 1=empty, 2=exception
- **File output**: `run_space/clip_input.txt` (ASCII encoded)

## Cross-Module Communication

- **Shared state**: Via `.txt` files (directories lists, status flags)
- **No direct subprocess calls** between modules; launchers orchestrate
- **Metadata**: tagScanner uses `enteredDirectories.txt` to know where to scan
- **Sentinel pattern**: Use `status.txt` + lock files to coordinate

## Conventions

- **Paths**: Use local folder names (e.g., `set "TargetFolder=%~dp0%~n0"` deriving from script location)
- **Temp files**: Always in `run_space/`; never scatter across system
- **Encoding**: Prefer ASCII for batch-generated files to avoid BOM surprises
- **Error handling**: Check `%ERRORLEVEL%` after PowerShell calls; log to console with `[INFO]`, `[WARN]`, `[ERROR]` prefixes
- **Comments**: Batch uses `::` or `REM`; PowerShell uses `#` or `<# #>`
