# Copilot Instructions for cmd Workspace

## 📋 Table of Contents
1. [AI Assistant Guidance](#ai-assistant-guidance)
2. [User Communication Protocol](#user-communication-protocol)
3. [User-Centric Design Principles](#user-centric-design-principles)
4. [Continuous Improvement & Learning](#continuous-improvement--learning)
5. [Critical Rules (Zero Manual Input & Testing Environment)](#critical-rules)
6. [Project Overview & Architecture](#project-overview--architecture)
7. [Critical Patterns & Conventions](#critical-patterns--conventions)
8. [New Program Creation Workflow](#new-program-creation-workflow)
9. [Program Requirements Checklist](#program-requirements-checklist)
10. [Feature List Printing](#feature-list-printing)
11. [Editing Existing Programs](#editing-existing-programs)
12. [Code Organization & Language Selection](#code-organization--language-selection)
13. [Testing & Debugging](#testing--debugging)
14. [Input Timing Tracking System](#input-timing-tracking-system)
15. [Error Tracking System](#error-tracking-system)
16. [Quick Reference](#quick-reference)

---

## 🤖 AI Assistant Guidance

**READ THESE INSTRUCTIONS CAREFULLY - They define how you work in this workspace.**

### Core Principles
1. **Test Everything**: Always run programs in `_debug/automated_testing_environment/` - NEVER execute main programs
2. **Automate Input**: Design all prompts to accept piped input - user should NEVER type manually during testing
3. **ASCII Only**: Use ASCII characters (`*`, `-`, `=`) in terminal output - NO Unicode bullets (•), arrows (→), boxes (┌─┐)
4. **Check Output**: If you see garbled characters like `â€¢`, `Â`, investigate and replace Unicode with ASCII
5. **Ask First**: When request is unclear, clarify before acting - when clear, proceed immediately

**Diagnostics & Logs**
- When errors occur or behavior seems wrong, check relevant log files first (e.g., _debug/logs, keyboard.log).
- If user-reported symptoms are unclear, request screenshots to confirm UI state.
- Track keystrokes (keyboard.log) to reconstruct sessions and override/fix values based on captured input when needed.
- If programs exit unexpectedly during test runs, rerun with KEEP_GUI_OPEN=1 to keep the GUI open for debugging and capture screenshots/logs.

### When You See Weird Characters
If terminal output shows `â€¢`, `â†'`, `â"€`, etc., this means:
- **Problem**: Unicode characters (•, →, ─) in source code
- **Cause**: Windows terminals don't display UTF-8 correctly
- **Fix**: Replace with ASCII (`*`, `>`, `-`)
- **Search**: Use grep to find Unicode in code
- **Test**: Verify output looks clean after fix

### Testing Protocol
```powershell
# ALWAYS use this pattern for testing:
cd _debug/automated_testing_environment
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item ..\..\run.bat .
Copy-Item ..\..\implementation.ps1 .
"input1\ninput2\nq\n" | .\run.bat  # Piped input only!
```

### UI Debug Mode (For Programs with User Interfaces)

**When debugging UI programs (interactive menus, forms, buttons, text boxes), use programmatic controls to simulate user actions instead of manual interaction.**

✅ **Debug Mode Requirements**:
- Add `--debug` CLI flag or `$debugMode` environment variable to enable debug logging
- When debug mode enabled:
  1. **Log all UI state** to `_debug/logs/ui-debug.log` (menu items, current selection, highlight index, shift key state, form values, etc.)
  2. **Log all inputs** before processing (keystroke, selection index, text entry, button click)
  3. **Provide CLI overrides** to control UI without manual input:
     - `--debug-menu <path>` - Jump directly to specific menu/form path
     - `--debug-select <index>` - Simulate selecting option at index N (for menus)
     - `--debug-input <value>` - Simulate text input into form field
     - `--debug-key <key>` - Simulate key press (for arrow keys, Enter, Escape, Shift, etc.)

✅ **UI State Logging Format** (Timestamp, context, current state):
```
[2025-12-06 12:34:56] MenuDisplay - currentPath=mainUI.settings, items=3, selectedIndex=1, highlightColor=Green
[2025-12-06 12:34:57] KeyInput - key=Down, shiftHeld=false
[2025-12-06 12:34:57] MenuDisplay - currentPath=mainUI.settings, items=3, selectedIndex=2, highlightColor=Green
[2025-12-06 12:34:58] KeyInput - key=Enter+Shift, shiftHeld=true
[2025-12-06 12:34:58] DescriptionBox - itemName=Edit Settings, description=Modify settings.ini, displayed=true
```

✅ **Debugging Without Manual Input**:
- **DO NOT** wait for user to press keys during AI testing/debugging
- **DO** create CLI flags/env vars to simulate user actions
- **DO** test via: `.\run.bat --debug-menu mainUI.settings --debug-select 1 --debug-key Enter`
- **DO** capture full UI state in logs before/after each simulated action
- **DO** read logs to verify UI behaved correctly

✅ **Test Automation**:
```powershell
# Test menu navigation via debug flags
"" | .\run.bat --debug-menu mainUI.settings --debug-select 0  # Back
"" | .\run.bat --debug-menu mainUI --debug-select 1           # Select submenu
"" | .\run.bat --debug-select 1 --debug-key Enter             # Select option
```

**Rationale**: UI programs require deterministic, repeatable testing. Manual keyboard input is non-deterministic and blocks automation. Debug mode with CLI overrides enables full automated testing of UI logic.

### What Makes Instructions Clear for AI
- ✅ **Concrete examples** with exact commands
- ✅ **Visual markers** like ⚠️, ✅, ❌ for quick scanning
- ✅ **Before/After** comparisons showing the right way
- ✅ **Step-by-step** workflows with numbered lists
- ✅ **Common mistakes** section with solutions
- ❌ **Avoid vague** phrases like "properly handle" - specify HOW
- ❌ **Avoid assumptions** - state requirements explicitly

---

## 💬 User Communication Protocol

**When user provides unclear or ambiguous requests:**

1. **Clarify First**: Ask specific questions to understand intent before taking action
2. **Confirm Understanding**: Restate the request in clear technical terms
3. **List Actions**: Show what you plan to do step-by-step
4. **Wait for Approval**: Get explicit confirmation before proceeding

**Examples of clarification:**
- User: "fix the thing" → Ask: "Which file/program needs fixing? What specific issue are you seeing?"
- User: "add that feature" → Ask: "Which feature specifically? Where should it be added?"
- User: "make it better" → Ask: "What aspect should be improved? Performance, readability, features?"
- User: "update the settings" → Ask: "Which settings file? What should be updated?"

**When request is clear, proceed immediately without asking.**

---

## 👤 User-Centric Design Principles

**Always consider the user's perspective when designing/improving programs:**

✅ **Evaluate from User Standpoint**:
- **What works well?** Identify successful patterns and UX choices
- **What could improve?** Look for friction points, confusing workflows, repetitive steps
- **Is it necessary?** Every feature should solve a real problem
- **Is it intuitive?** Complex features should have clear documentation
- **Can it be simpler?** Sometimes less is more - don't over-engineer

✅ **Provide Constructive Feedback**:
- When implementing a feature, note: "This approach handles X well" or "Consider simplifying Y"
- Suggest improvements: "Users might prefer if..." or "This could be clearer if..."
- Document trade-offs: "This prioritizes [goal] over [goal]"

✅ **Learn from Each Program**:
- After completing a program, observe what patterns work best
- Update these instructions based on successful implementations
- Document lessons learned for similar future programs

---

## 🔄 Continuous Improvement & Learning

**CRITICAL: Periodically review and update these instructions. Do NOT assume instructions are static.**

✅ **Instruction Review Workflow**:
- **When**: Before starting major new programs or after completing significant features
- **Where**: This file (`.github/copilot-instructions.md`)
- **What to Check**: 
  - Do the patterns documented still match how you actually work?
  - Have new patterns emerged that should be documented?
  - Are there contradictions between sections?
  - Did the user request new guidelines that should be formalized?
- **Action**: Update relevant sections; consolidate lessons learned; remove outdated patterns

✅ **After Each Implementation**:
- Review what error handling patterns worked best
- Note which UX patterns felt natural vs. awkward
- Document any new insights about your preferences
- Consider if similar programs should use discovered patterns
- **Update instructions** if you discover better approaches

✅ **Error Handling Lessons**:
- Track common error scenarios across programs
- Note your preferred error message styles
- Document which recovery strategies you prefer
- Update instructions with proven patterns

✅ **User Preference Signals**:
- When user asks for "improvements", document what that means
- When user requests changes, add them to instructions for consistency
- Note user preferences on code style, organization, feature priority
- Build a knowledge base of specific needs
- **ALWAYS add explicit UI/debugging requests to the relevant section**

✅ **Instruction Updates**:
- Add new patterns when you discover better approaches
- Remove or deprecate patterns that don't work
- Clarify ambiguous guidance based on user feedback
- Keep instructions practical and project-specific
- **Date major updates** (e.g., "Added UI Debug Mode section - 2025-12-06")

---

## ⚠️ CRITICAL RULE: ZERO MANUAL INPUT DURING TESTING

**When AI is testing/debugging programs, user should NEVER need to type anything manually.**

- ✅ **DO**: Design all prompts to accept piped input from the beginning
- ✅ **DO**: Test with: `"input1\ninput2\nq\n" | .\run.bat`
- ✅ **DO**: Handle null/empty input gracefully (pipe exhaustion)
- ✅ **DO**: Wrap all `Read-Host` in try-catch with null checks
- ❌ **DON'T**: Create programs that require manual keyboard input during tests
- ❌ **DON'T**: Assume input will always be available
- ❌ **DON'T**: Let `Read-Host` crash when piped input ends

**If user needs to manually type during a test, the program is incorrectly designed - fix it.**

---

## ⚠️ CRITICAL RULE: ALWAYS USE TESTING ENVIRONMENT

**AI must ONLY run programs in the isolated testing environment. User runs the actual program.**

- ✅ **DO**: Clear `_debug/automated_testing_environment/` before each test
- ✅ **DO**: Copy only necessary files to test environment
- ✅ **DO**: Run ALL tests inside `automated_testing_environment/`
- ✅ **DO**: Announce in chat: "Running test in automated environment"
- ❌ **DON'T**: Run main executable from program root directory
- ❌ **DON'T**: Test in main workspace (pollutes user's environment)
- ❌ **DON'T**: Execute program without explicit user permission if outside test env

**Testing Location**: `program/_debug/automated_testing_environment/`  
**User's Program**: `program/run.bat` (AI never touches this during testing)

**If you run a program outside the testing environment, you are violating protocol.**

---

## 🎯 Project Overview & Architecture

**cmd** is a collection of Windows batch/PowerShell automation tools orchestrating system tasks through a **dual-dispatch pattern**: root-level launcher scripts check `status.txt`, then spawn parallel task modules.

### Core Pattern: Status-Gated Parallel Dispatch
- **Root launchers** (`executeforMusic.bat`, `tagScanner.bat`): Check `status.txt` for `"false"` before execution
- **Task modules** (directories): Contain `status.txt`, `run.bat`, and `_temp_locks/` for synchronization
- **Lock files** (`_temp_locks/*.lock`): Temp sentinels deleted on completion; launcher waits until all gone

### Key Modules in Workspace

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

7. **settings** - Centralized settings manager
   - PowerShell backend with batch launcher
   - Manages settings.ini for other programs
   - Internal config in .internal_config
   - Numbered selection lists, custom sections, debug menu options

---

## 🔑 Critical Patterns & Conventions

### Encoding & BOM Handling
- **Strip BOM**: Use `Get-Clipboard` + trim `[char]0xFEFF` when reading from clipboard
- **Write ASCII/UTF8**: Avoid Set-Content BOM by using `-Encoding ASCII` or piping via `more` to strip spurious BOMs
- **Example** (`updatingExecutor\run.bat`, lines 25-35): Inline PowerShell generation with explicit ASCII encoding
- **Character Safety**: ALWAYS use ASCII-safe characters in terminal output (asterisks `*`, hyphens `-`, equals `=`)
- **Avoid Unicode**: Do NOT use Unicode characters like bullets (•), arrows (→), boxes (┌─┐) in Write-Host output
- **Why**: Windows terminals may not display UTF-8 correctly, causing garbled output like `â€¢` instead of `•`
- **Safe Alternatives**: Use `*` for bullets, `>` for arrows, `=` and `-` for borders
- **Testing**: If you see weird characters (â€¢, Â, etc.) in terminal output, replace Unicode with ASCII

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
- **Pattern**: `settings.txt` or `settings.ini` with key=value pairs (e.g., `debug=true`)
- **Example**: tagScanner uses `settings.txt`; updatingExecutor uses `settings.ini`
- **Location**: Store settings in module root, not run_space
- **Common settings**: debug, timeout_seconds, auto_cleanup, log toggles

### Developer Workflows

**Running a Launcher**:
```batch
cd c:\Users\cmand\OneDrive\Desktop\cmd
executeforMusic.bat  # Checks status.txt, launches tasks in parallel
```

**Parallel Execution Sync**:
1. Launcher creates `_temp_locks/` if missing
2. For each target script, creates `taskname.bat.lock`
3. Starts each script: `start cmd /c "call script.bat & del lockfile"`
4. Launcher waits in loop checking `dir _temp_locks\*.lock` (when count=0, all done)

**Adding a New Module**:
1. Create folder: `newModule/`
2. Add: `status.txt` (containing "true" or "false")
3. Add: `run.bat` (or `.ps1` wrapped by `run.bat`)
4. Add: `_temp_locks/` (empty folder)
5. (Optional) Add: `settings.ini` or `settings.txt` if config needed
6. Update root launcher to include module

**Cross-Module Communication**:
- **Shared state**: Via `.txt` files (directories lists, status flags)
- **No direct subprocess calls** between modules; launchers orchestrate
- **Sentinel pattern**: Use `status.txt` + lock files to coordinate

**Conventions**:
- **Paths**: Use local folder names (e.g., `set "TargetFolder=%~dp0%~n0"`)
- **Temp files**: Always in `run_space/`; never scatter across system
- **Encoding**: Prefer ASCII for batch-generated files to avoid BOM surprises
- **Error handling**: Check `%ERRORLEVEL%` after PowerShell calls
- **Status messages**: Use `[INFO]`, `[WARN]`, `[ERROR]` prefixes
- **Comments**: Batch uses `::` or `REM`; PowerShell uses `#` or `<# #>`

---

## 🆕 New Program Creation Workflow

**CRITICAL**: Follow this exact process for all new programs:

1. **Plan First**: List all implementation steps before starting any work
2. **Design for Automation**: All input must be pipeable/automatable - NO manual input required during testing
3. **Execute Sequentially**: Complete each step fully before moving to the next
4. **No Improvisation**: Do not add features or changes beyond the listed steps
5. **Test After Each Feature**: Design test with piped inputs, run in `_debug/automated_testing_environment/`, verify
6. **Seek Clarification**: If a step is unclear, ask rather than guessing
7. **Consider User Experience**: Evaluate from user's standpoint - what works well, what could improve
8. **Print Feature Summary**: At completion, display feature list categorized by type (see Feature List Printing section)

**INPUT HANDLING RULE**: Every program MUST accept piped input from day one. When testing/debugging, user should NEVER need to manually type anything. Design all prompts to work with automated input: `"answer1\nanswer2\nq\n" | .\run.bat`

**TESTING ENVIRONMENT RULE**: AI must ONLY run programs inside `_debug/automated_testing_environment/`. Never execute the main program directly. Only the user runs the actual program from its root directory.

---

## ✅ Program Requirements Checklist

Follow these guidelines to ensure consistency, maintainability, and ease of debugging:

### 1. Core Architecture

✅ **Main Executable**: Windows batch file (.bat) as entry point
- Can use other languages (Python, PowerShell, C++) for implementation
- Batch file orchestrates execution flow

✅ **Execution Model**: Single-run invocations (no infinite loops)
- If loops necessary, provide automated exit in debug mode
- Use timeout_seconds setting to prevent runaway execution

✅ **Dual Execution Support**: Works from terminal AND as double-clickable executable

✅ **Automated Input Support** (CRITICAL):
- **ALL prompts must accept piped input** - design from the beginning
- Test with: `"input1\ninput2\nq\n" | .\run.bat`
- Handle null/empty input gracefully (when pipe exhausts)
- Use `Read-Host` with try-catch and null checks in PowerShell
- **User should NEVER type manually during testing/debugging**
- Add `-NoNewline` when prompting to work better with automation

✅ **Workspace Structure**:
```
program/
├── run.bat              # Main executable
├── implementation.*     # PowerShell, Python, etc.
├── settings.ini         # Configuration
├── README.md            # Auto-generated on first run
├── run_space/           # Temp execution artifacts
└── _debug/
    ├── logs/            # All log files
    ├── automated_testing_environment/
    └── backups/         # Version backups
```

### 2. Logging System

✅ **Location**: `_debug/logs/` directory  
✅ **Format**: All entries include timestamps (YYYY-MM-DD HH:MM:SS)  
✅ **Control**: All logging configurable via settings file

**Available Logs**:
- `input.log` - User inputs and commands
- `important.log` - Critical program decisions and state changes
- `error.log` - Errors and exceptions with stack traces
- `output.log` - Program outputs and results
- `terminal.log` - Terminal/console output capture
- `debug.log` - Verbose debugging information
- `function_calls.log` - Function execution trace
- `performance.log` - Response times, throughput, latency metrics

**Settings Configuration**:
```ini
[Logging]
log_input=true
log_important=true
log_error=true
log_output=true
log_terminal=false
log_debug=false
log_function_calls=false
log_performance=false
log_rotation_size_mb=10
```

**Implementation**:
- Check settings before writing to each log type
- Default: Enable only input, important, error, output logs
- Provide helper function: `IsLogEnabled("input")` or `Get-Setting("log_input", "true")`
- Implement rotation when files exceed threshold (default 10MB)
- Archive old logs as `filename_YYYY-MM-DD.log`

### 3. Settings Management

✅ **Settings File** (settings.ini or settings.txt):
```ini
[General]
debug_mode=false           # Enable debug features
timeout_seconds=300        # Execution timeout (0 to disable)
auto_cleanup=true          # Clean temp files on exit
verbose_output=false       # Detailed console output
progress_indicators=true   # Show progress bars

[Logging]
log_input=true            # Log user inputs
log_important=true        # Log critical decisions
log_error=true            # Log exceptions
log_output=true           # Log program output
# ... other log toggles

[Advanced]
# Program-specific settings
```

**Dynamic Settings Pattern**:
- Load settings at program start into variables/dictionary
- Provide helper function: `GetSetting("debug_mode", "false")`
- Generate default settings file on first run with inline comments
- Handle missing settings file gracefully with defaults
- Optional: Create settings GUI via separate executable or `/settings` CLI arg

### 4. Debug Mode

✅ **Control**: Via `debug_mode=true/false` in settings file  
✅ **Features when enabled**:
- Clear workspace (except executable) on exit
- Auto-accept prompts for automated testing
- Enable verbose logging
- Show debug-only menu options (like Settings Manager's [T] and [I])
- Timeout enforcement for testing

### 5. Code Quality

✅ **Documentation**:
- Comprehensive inline comments explaining logic
- README.md auto-generated on first run
- Must include: purpose, features, usage, structure

✅ **Modular Design**:
- Separate code into distinct functions/modules
- Clear function names with descriptive parameters
- Use approved verbs for PowerShell (Get-, Set-, Test-, Invoke-)

✅ **Security & Validation**:
- Validate all inputs before processing
- Sanitize outputs before displaying
- Use try-catch blocks around risky operations
- Check file existence before reading/writing

✅ **Error Handling**:
- Clear error messages with `[INFO]`, `[WARN]`, `[ERROR]` prefixes
- Guide users on how to resolve issues
- Reference log files for details
- Provide error codes where applicable
- Check `%ERRORLEVEL%` after PowerShell calls in batch

✅ **Termination Handling**:
- Implement cleanup function (e.g., `Invoke-Cleanup`)
- Call cleanup on all exit paths: Q/quit, Ctrl+C, timeout, errors
- Register Ctrl+C handler to prevent leaving temp files
- Release resources, close file handles, delete lock files
- Dispose file watchers and other system objects

✅ **File Change Detection** (Optional but Recommended):
- Use `FileSystemWatcher` to monitor configuration files
- Auto-reload settings when files are modified externally
- Display clear notification when external changes detected
- Update timestamp tracking after internal saves to prevent false positives
- Example: Settings Manager detects manual edits to settings.ini
- Dispose watcher in cleanup function

✅ **AI-Friendly Code**:
- Clear variable names (descriptive, not abbreviated)
- Consistent structure across similar programs
- Follow language-specific conventions
- Use standard libraries before external dependencies

✅ **Code Optimization**:
- When debugging/fixing code, it's OK to refactor and shorten verbose sections
- Consolidate repetitive patterns into functions
- Remove redundant checks or duplicate logic
- Keep files under 1000 lines when possible through modularization
- Balance readability with conciseness

### 6. User Experience

✅ **Status Messages**:
- `[INFO]` for normal operations
- `[WARN]` for recoverable issues
- `[ERROR]` for failures
- Progress indicators for long operations

✅ **Input Patterns** (MUST BE AUTOMATABLE):
- **Design ALL prompts to work with piped input from the start**
- Use numbered selection lists (avoid typing setting names)
- Allow Q/q to cancel operations gracefully
- Handle empty/null input without crashing (pipe exhaustion)
- Validate input ranges before processing
- Wrap `Read-Host` in try-catch blocks
- Check for null: `if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }`
- **Testing rule**: User should NEVER manually type during tests

✅ **User Documentation**:
- Provide guides in `guides/` directory (parent of program)
- Include: installation, usage, troubleshooting
- Keep guides updated with program changes

---

## 📊 Feature List Printing

**When creating a new program, ALWAYS print a feature summary at the end with this format:**

```
╔═══════════════════════════════════════════════════════════════════╗
║                      PROGRAM: [Name]                              ║
║                    Feature Implementation Summary                 ║
╚═══════════════════════════════════════════════════════════════════╝

✅ CORE FEATURES
  • Feature 1 description
  • Feature 2 description
  • Feature 3 description

✅ USER EXPERIENCE
  • Numbered selection lists (no typing setting names)
  • Piped input support (automated testing)
  • Graceful error handling with helpful messages

✅ ARCHITECTURE
  • Main executable: run.bat
  • Implementation: Manage-Settings.ps1
  • Settings file: settings.ini
  • Internal config: .internal_config

✅ LOGGING & MONITORING
  • Log location: _debug/logs/important.log
  • Configurable logging via settings
  • Timestamps on all entries

✅ TESTING
  • Automated input support (no manual typing)
  • Runs in _debug/automated_testing_environment/
  • Exit code 0 on all successful runs

✅ DEBUG MODE
  • Admin password protection (default: admin)
  • Enhanced editing capabilities
  • Internal config editor access

All tests passed ✅ | Exit code 0 ✅ | Production ready ✅
```

**Categories to include** (customize per program):
- **CORE FEATURES**: Main functionality
- **USER EXPERIENCE**: Input patterns, menus, feedback
- **ARCHITECTURE**: File structure, design patterns
- **LOGGING & MONITORING**: Log types and locations
- **TESTING**: Test environment, automation support
- **DEBUG MODE**: Debug features (if applicable)
- **SECURITY**: Validation, encryption, access control
- **PERFORMANCE**: Optimization, speed considerations
- **INTEGRATION**: How it works with other programs

---

## ✏️ Editing Existing Programs

### Pre-Edit Protocol

**Backup Requirements**:
1. **ALWAYS ask** before editing a working program you haven't modified before
2. If user approves backup:
   - Create `_debug/backups/` folder if needed
   - Copy to `backups/program_v[X.Y].bat` with incremented version
3. If user declines: Edit directly without backup
4. **Re-ask** if user states "this program works" or status is unknown

### Editing Guidelines

- Maintain original structure and conventions
- Document rationale for all changes
- Test thoroughly in automated test environment
- Check for regressions in existing functionality
- Update README.md if behavior changes

### Code Refactoring During Debugging

When fixing bugs or improving existing code:
- **Simplify verbose sections** - consolidate repetitive patterns into reusable functions
- **Shorten long files** - if a file approaches 1000 lines, break it into modules
- **Remove redundancy** - eliminate duplicate checks, redundant variables, dead code
- **Optimize logic** - replace complex nested conditions with clearer patterns
- **Keep it readable** - shorter is better only if it remains understandable

Balance: Prioritize working code > concise code > perfect code

### Change Documentation

**Do NOT create separate change reports or markdown files**

Document changes within the program's directory:
- Add entries to `_debug/ERROR_TRACKING.md` if fixing bugs
- Update `README.md` if features/behavior change
- Keep documentation within program's own structure

---

## 📦 Code Organization & Language Selection

**Auto-detect when to modularize code and which language/approach to use.**

### When to Add to Existing File vs Create Separate Module

✅ **Add to existing file when**:
- Adding a single small function (< 50 lines)
- Minor feature that uses existing imports/dependencies
- Modifying existing functionality directly
- Total file size will stay under 800 lines
- Feature is tightly coupled to existing code
- No new external dependencies required

✅ **Create separate module/file when**:
- Adding substantial new feature (> 100 lines)
- File will exceed 800-1000 lines after addition
- New feature has distinct responsibility (separation of concerns)
- New external dependencies needed (different language/library)
- Feature could be reused across multiple programs
- Adding multiple related functions (e.g., all database operations, all API calls)
- Performance-critical code (C++, compiled component)
- Cross-language integration needed

### Language Selection Matrix

**Choose implementation language based on task requirements:**

| Task Type | Best Language | Rationale |
|-----------|---------------|-----------|
| **File operations, system tasks** | PowerShell | Native Windows integration, rich cmdlets |
| **Text processing, parsing** | PowerShell or Python | Regex support, string manipulation |
| **CLI menu systems** | PowerShell | Terminal control, ReadKey() for interactive UX |
| **Web scraping, API calls** | Python | requests, BeautifulSoup, json libraries |
| **Data analysis, CSV/JSON** | Python or PowerShell | pandas (Python) or Import-Csv (PowerShell) |
| **Performance-critical loops** | C++ or C# | Compiled speed for heavy computation |
| **GUI applications** | C# (WinForms/WPF) | Rich UI controls, event handling |
| **Clipboard operations** | PowerShell | Built-in Get-Clipboard, Set-Clipboard |
| **Registry access** | PowerShell or Batch | Native Windows Registry cmdlets |
| **Process management** | PowerShell or Batch | Get-Process, Start-Process, taskkill |
| **Image/media processing** | Python | PIL, OpenCV, moviepy libraries |
| **Database operations** | Python or C# | SQLAlchemy, Entity Framework |
| **Network operations** | PowerShell or Python | Test-NetConnection, socket library |
| **Automation/scheduling** | Batch + PowerShell | Task Scheduler integration |

### Terminal-Based UI with Multi-Language Backends

**Key Principle**: The UI must display in PowerShell (terminal), but backend implementation can use any language.

**Supported Architecture**:
```
PowerShell Frontend (UI Rendering)
    ↓
    ├─ Python Backend (data processing, algorithms)
    ├─ C++ Binary (performance-critical code)
    ├─ C# Component (Windows-specific features)
    ├─ Node.js Script (complex logic)
    └─ External Executables (any language)
    ↓
JSON/Text Output → ANSI Codes → PowerShell Terminal
```

**UI Display Requirements**:
- ✅ Output to stdout (readable by PowerShell)
- ✅ Support ANSI color codes (16-color palette)
- ✅ Plain text rendering (unicode safe for Windows terminals)
- ✅ Return data via JSON, CSV, or plain text
- ✅ Accept input via: pipes, files, command-line args, stdin

**Backend Implementation Options**:

| Backend | Best For | Integration |
|---------|----------|-------------|
| **Python** | Data processing, ML, file ops, web requests | Call via `python script.py`, parse JSON output |
| **C++** | Performance-critical loops, complex algorithms | Compile to .exe, call with args, read output |
| **C#** | Windows integration, database ops, rich types | Compile to .exe or .dll, JSON serialization |
| **Node.js** | Complex UI logic, async operations, APIs | Call via `node script.js`, JSON IPC |
| **Go** | Fast binaries, concurrent operations, CLI | Single binary, easy cross-platform |
| **Rust** | Safety + performance, system programming | Compiled binary, minimal dependencies |

**Pattern: PowerShell Orchestrates, Backend Processes**

```powershell
# PowerShell (run.bat → run.ps1)
$inputData = @{ menu = "main"; selection = 1 } | ConvertTo-Json
$output = python backend_processor.py $inputData | ConvertFrom-Json

# Render to terminal
Write-Host $output.menuDisplay -ForegroundColor $output.color
$userInput = Read-Host "Enter choice"

# Python (backend_processor.py)
import json, sys
data = json.loads(sys.argv[1])
result = {
    "menuDisplay": "1. Option A\n2. Option B",
    "color": "Green",
    "menuData": [...]
}
print(json.dumps(result))
```

**Common Integration Patterns**:

1. **Batch + PowerShell + Python**:
   ```batch
   @echo off
   powershell -ExecutionPolicy Bypass -File run.ps1 %*
   ```
   ```powershell
   $data = python process.py $args | ConvertFrom-Json
   Write-Host $data.ui
   ```

2. **Batch + C++ Binary**:
   ```batch
   @echo off
   set /p input="Enter data: "
   processor.exe "%input%" > output.txt
   type output.txt
   ```

3. **PowerShell + Node.js**:
   ```powershell
   $output = node backend.js | ConvertFrom-Json
   Show-Menu $output.menu
   ```

4. **PowerShell + C# Compiled**:
   ```powershell
   $result = & .\Processor.exe --input $data
   ConvertFrom-Json $result | ForEach-Object { Write-Host $_.display }
   ```

**Data Format Guidelines**:
- Use **JSON** for complex data structures
- Use **CSV** for tabular data
- Use **plain text** for simple strings
- Always include **error codes** (exit code 0 = success)
- Always **escape output** before rendering in terminal

**ANSI Color Code Support**:
```powershell
# PowerShell natively supports ANSI codes
Write-Host "Green text" -ForegroundColor Green      # Native
Write-Host "`e[32mGreen text`e[0m"                   # ANSI escape

# Python can output ANSI codes
print("\033[32mGreen text\033[0m")  # Python
```

**Performance Considerations**:
- **Fast UI response**: Use fast languages (C++, Go, Rust)
- **Heavy processing**: Offload to Python/C++ backend
- **File I/O**: Python or PowerShell (fast enough)
- **Real-time data**: Node.js async operations
- **Memory-intensive**: C++ for low-overhead processing

**Example: uiBuilder Multi-Language Architecture**
```
uiBuilder/
├── run.bat                 # Batch launcher
├── UI-Builder.ps1         # PowerShell UI orchestrator
├── modules/
│   ├── ui/MenuDisplay.ps1 # Terminal rendering
│   ├── processor.py        # Data processing (if added)
│   └── utils/
│       └── calculator.exe  # C++ binary (if added)
├── button.list            # CSV data
└── _debug/
    └── logs/              # Timing & event logs
```

**When to Use Each Language**:
- **PowerShell only**: Simple menus, file ops, system tasks
- **PowerShell + Python**: Add data processing, machine learning, complex logic
- **PowerShell + C++**: Add performance-critical algorithms
- **PowerShell + C#**: Add Windows-specific features, database operations
- **PowerShell + Node.js**: Add async operations, real-time updates

**Testing Multi-Language Programs**:
```powershell
# Test PowerShell frontend
"1\n2\nq\n" | .\run.bat

# Test Python backend directly
python backend.py '{"key":"value"}'

# Test C++ binary directly
.\processor.exe --test

# Full integration test
.\run.bat --test-mode
```

### Module Organization Patterns

**Pattern 1: Helper Module**
```
program/
├── run.bat                    # Main entry point
├── implementation.ps1         # Core logic
├── modules/
│   ├── database-ops.ps1      # Database functions
│   ├── string-utils.ps1      # Text processing
│   └── api-client.py         # External API calls
└── _debug/
```

**Pattern 2: Language Bridge**
```
program/
├── run.bat                    # Launcher
├── orchestrator.ps1           # Coordinates workflow
├── processor.py               # Heavy data processing
├── renderer.cs                # UI rendering (compiled)
└── run_space/
    └── temp_data.json        # Inter-process communication
```

**Pattern 3: Plugin Architecture**
```
program/
├── run.bat
├── core.ps1                   # Plugin loader
├── plugins/
│   ├── plugin-auth.ps1       # Authentication
│   ├── plugin-logging.ps1    # Logging
│   └── plugin-export.py      # Export formats
└── settings.ini              # Plugin enable/disable flags
```

### Decision Flowchart

When adding functionality, follow this decision tree:

1. **Is it < 50 lines and uses existing dependencies?**
   - YES → Add to existing file
   - NO → Continue

2. **Will the file exceed 800 lines?**
   - YES → Create separate module
   - NO → Continue

3. **Does it require a different language for better performance/capability?**
   - YES → Create separate file in appropriate language
   - NO → Continue

4. **Is it a distinct responsibility (database, API, UI, file I/O)?**
   - YES → Create separate module
   - NO → Add to existing file

5. **Could this be reused in other programs?**
   - YES → Create in shared `modules/` or `lib/` directory
   - NO → Add to existing file

### Cross-Language Communication

**JSON Files** (Preferred for Python ↔ PowerShell):
```powershell
# PowerShell writes
@{ key = "value" } | ConvertTo-Json | Set-Content data.json
# Python reads
import json
with open('data.json') as f: data = json.load(f)
```

**Exit Codes** (Simple success/failure):
```batch
python script.py
if %ERRORLEVEL% NEQ 0 goto error
```

**Stdout Piping** (Quick data transfer):
```powershell
$result = python script.py | ConvertFrom-Json
```

**Shared Config File** (settings.ini for all languages):
```ini
[Database]
connection_string=...  # Read by both PS1 and PY
```

### Examples from Workspace

**Good: Monolithic** (updatingExecutor)
- Single PS1 file with inline functions
- All clipboard operations in one place
- < 500 lines, cohesive purpose

**Good: Modular** (settings)
- `Manage-Settings.ps1` (core logic)
- `modules/config/` (config parsing)
- `modules/powershell/` (PS-specific helpers)
- Separation by responsibility

**Good: Multi-Language** (tagScanner)
- Batch launcher detects metaflac.exe vs TagLib DLL
- PowerShell for file operations
- C# TagLib-Sharp for ID3 tag manipulation

### Auto-Detection Checklist

Before writing code, ask:
- ✅ What language best suits this task? (see matrix above)
- ✅ Is this < 50 lines? → Add inline
- ✅ Is this 50-200 lines? → Consider separate function in same file
- ✅ Is this > 200 lines? → Create separate module
- ✅ Does file exceed 800 lines? → Mandatory modularization
- ✅ Does it need Python/C++ libraries? → Separate file in that language
- ✅ Is it reusable? → Place in `modules/` or `lib/`

**When in doubt**: Err on the side of creating a separate module. It's easier to merge later than to untangle monolithic code.

---

## 🧪 Testing & Debugging

### Automated Testing Environment (MANDATORY)

**Location**: `_debug/automated_testing_environment/`  
**Purpose**: Isolated testing without polluting main workspace  
**Access**: AI ONLY runs programs here, user runs actual program from root

**Testing Workflow** (AI MUST FOLLOW):
1. **Announce**: State in chat "Running test in automated_testing_environment"
2. **Clear**: `Remove-Item automated_testing_environment\* -Recurse -Force`
3. **Copy**: `Copy-Item run.bat, implementation.ps1 automated_testing_environment/`
4. **Navigate**: `cd automated_testing_environment`
5. **Execute**: `.\run.bat` (with piped inputs)
6. **Verify**: Check outputs and logs inside test environment
7. **Document**: Add to `_debug/ERROR_TRACKING.md` if issues found

**AI Testing Rules** (NON-NEGOTIABLE):
- **ALWAYS** use automated testing environment when running programs
- **NEVER** run main executable from program root directory
- **NEVER** execute `cd program; .\run.bat` - this is user's territory
- **ANNOUNCE** in chat before starting each test run
- **AUTO-HANDLE** all terminal inputs - pipe defaults, use test data
- **USER SHOULD NEVER TYPE MANUALLY** during AI tests
- **ASK PERMISSION** if you absolutely must run program outside test env (rare)

**Input Automation Examples** (REQUIRED FORMAT):
```powershell
# Pipe single input
"q`n" | .\run.bat

# Pipe multiple inputs (use for all tests)
"3`nGeneral`ntest_setting`ntest_value`nTest description`n1`nq`n" | .\run.bat

# Use test data file
Get-Content test_inputs.txt | .\run.bat

# Empty input handling test
"" | .\run.bat  # Should exit gracefully, not crash
```

**CRITICAL**: If a program requires manual input during testing, it is **incorrectly designed**. Go back and add null checks and try-catch blocks around all `Read-Host` calls.

**This ensures**:
- Clean isolated testing
- No pollution of main workspace
- Easy cleanup between runs
- Predictable behavior for debugging
- Seamless integration with CI/CD

---

## 🕐 Input Timing Tracking System

**Added**: 2025-12-07  
**Purpose**: Detect when programs wait for manual input vs automated AI input during testing

### Overview

When designing programs that accept user input, implement **input timing tracking** to detect if the program is blocking waiting for manual keypresses during AI testing. This identifies bugs where input handling isn't properly automated.

### Core Concept

- **AI Input (Automated)**: <0.1s between inputs ✅ Fast, consistent
- **Manual Input (User Typing)**: >2.0s between inputs ⚠️ Slow, thinking time
- **Hanging Input**: START without matching END ❌ Program frozen

### Implementation Pattern

**1. Add Timing Variables to Main Script**:
```powershell
$script:lastInputTime = Get-Date      # Track last input timestamp
$script:inputCounter = 0               # Sequential input counter
```

**2. Create Enhanced Log-Input Function**:
```powershell
function Log-Input {
    param(
        [string]$Message,
        [string]$Source = "Unknown"
    )
    if (-not $script:settings.Logging.log_input) { return }
    
    # Calculate timing
    $currentTime = Get-Date
    $timeSinceLastInput = ($currentTime - $script:lastInputTime).TotalSeconds
    $script:lastInputTime = $currentTime
    $script:inputCounter++
    
    # Detect unusual delays (>2 seconds suggests manual input)
    $delayIndicator = ""
    if ($timeSinceLastInput -gt 2.0 -and $script:inputCounter -gt 1) {
        $delayIndicator = " [DELAY: ${timeSinceLastInput}s - MANUAL INPUT SUSPECTED]"
    }
    
    $logFile = Join-Path $script:logsPath "input.log"
    $timingInfo = "(+${timeSinceLastInput}s)"
    "[$(Get-Timestamp)] INPUT #$($script:inputCounter) [$Source] $timingInfo${delayIndicator}: $Message" | Add-Content -Path $logFile -Encoding UTF8
}
```

**3. Create Timing Event Log**:
```powershell
function Log-InputTiming {
    param(
        [string]$Action,
        [string]$Details = ""
    )
    if (-not $script:settings.Logging.log_input) { return }
    
    $logFile = Join-Path $script:logsPath "input-timing.log"
    $timestamp = Get-Timestamp
    "[$timestamp] $Action | $Details" | Add-Content -Path $logFile -Encoding UTF8
}
```

**4. Wrap All Input Operations with Timing Calls**:
```powershell
# Before waiting for input
Log-InputTiming -Action "PROMPT_WAIT_START" -Details "Numbered menu awaiting input"

# Read input (should be fast with piped data)
$userInput = Read-Host "Enter number"

# After input received
Log-InputTiming -Action "PROMPT_WAIT_END" -Details "Input received"

# Log with source
Log-Input -Message $userInput -Source "NumberedMenu"
```

### Log Output Examples

**input.log** - Shows timing and detects delays:
```log
[2025-12-07 00:36:28] INPUT #1 [NumberedMenu] (+0.88s): 11
[2025-12-07 00:36:28] INPUT #2 [NumberedMenu] (+0.03s): Selected: 10
[2025-12-07 00:36:28] INPUT #3 [NumberedMenu] (+0.10s): 1
[2025-12-07 00:36:28] INPUT #4 [NumberedMenu] (+0.009s): Selected: 0
```
**Analysis**: All <0.2s = Fully automated ✅

**Detecting Manual Input**:
```log
[2025-12-07 00:36:28] INPUT #3 [NumberedMenu] (+0.05s): 2
[2025-12-07 00:36:35] INPUT #4 [NumberedMenu] (+7.2s) [DELAY: 7.2s - MANUAL INPUT SUSPECTED]: q
```
**Analysis**: 7 second delay = User manually typed "q" ⚠️

**input-timing.log** - Shows wait events:
```log
[2025-12-07 00:36:28] PROMPT_WAIT_START | Numbered menu awaiting input
[2025-12-07 00:36:28] PROMPT_WAIT_END | Input received
[2025-12-07 00:36:28] PROMPT_WAIT_START | Numbered menu awaiting input
[2025-12-07 00:36:28] PROMPT_WAIT_END | Input received
```
**Analysis**: All START/END pairs matched = Normal operation ✅

**Detecting Hung Input**:
```log
[2025-12-07 00:36:28] PROMPT_WAIT_START | Numbered menu awaiting input
(no matching END - program stuck here!)
```
**Analysis**: Missing END = Program hung waiting for manual input ❌

### Key Event Actions

| Action | Meaning | Timing |
|--------|---------|--------|
| `PROMPT_WAIT_START` | Waiting for text input (Read-Host) | Should match END <0.1s later |
| `PROMPT_WAIT_END` | Input received | Immediate |
| `INTERACTIVE_WAIT_START` | Waiting for arrow keys (ReadKey) | Should match END <0.1s later |
| `INTERACTIVE_WAIT_END` | Key received | Immediate |
| `DESCRIPTION_WAIT_START` | Description box displayed | Variable (user controlled) |
| `DESCRIPTION_WAIT_END` | User closed description | Variable |
| `DEBUG_KEY_SIMULATED` | Debug mode simulated key | Immediate |

### Troubleshooting

**Problem**: Test requires manual input
**Solution**: Check input.log for delays >2s, then add proper null checks to Read-Host calls

**Problem**: Program hangs during test
**Solution**: Check input-timing.log for START without END, then wrap blocking operations with try-catch

**Problem**: Automated test inconsistent
**Solution**: Check input-timing.log for variable timing, then verify piped input is working

### Settings Configuration

Enable input tracking in `settings.ini`:
```ini
[Logging]
log_input=true        # Enables input.log and input-timing.log
```

### Rules

1. **Every Read-Host must be wrapped** with try-catch for null handling
2. **Every input operation must log** with Source parameter
3. **Every blocking operation must log** WAIT_START and WAIT_END
4. **All delays >2s must be investigated** during testing
5. **No matching START/END is a bug** - fix immediately

### Verification Checklist

When testing a program:
- [ ] All inputs have timing info in input.log
- [ ] All timings <0.2s (no >2s delays)
- [ ] All WAIT_START have matching WAIT_END
- [ ] Source is identified for each input
- [ ] No MANUAL INPUT SUSPECTED warnings
- [ ] No gaps in input flow

---

## 📋 Error Tracking System

**Mandatory**: Maintain `ERROR_TRACKING.md` in `_debug/` directory for all programs

### When to Create Error Entries

- User reports unexpected behavior
- Automated tests fail
- Logic flaws discovered during code review
- Performance bottlenecks identified
- Integration issues between modules

### Error Entry Format

```markdown
## ERR-XXX: [Brief Title]

**Date**: YYYY-MM-DD  
**Severity**: High/Medium/Low  
**Status**: ✅ FIXED / ⚠️ IN PROGRESS / ❌ REGRESSION

### Description
[What went wrong - be specific]

### Root Cause
[Why it happened - technical explanation]

### Impact
[How this affects users]

### Solution
[What fixed it - include code snippets if relevant]

### Testing
[How the fix was verified]

### Files Modified
- file1.bat
- file2.ps1
```

### Best Practices

1. **Be Specific**: Exact failure description, not vague statements
2. **Reproduction Steps**: Include steps to reproduce if applicable
3. **Root Cause Analysis**: Understand why, not just what
4. **Multiple Attempts**: Document what didn't work and why
5. **Thorough Testing**: Multiple test cases before marking FIXED
6. **Cross-Reference**: Link related errors ("See ERR-002")
7. **Keep Concise**: 2-minute read maximum per entry

### Archive Policy

- When ERROR_TRACKING.md exceeds 1000 lines
- Archive old entries to ERROR_TRACKING_ARCHIVE_YYYY-MM.md
- Keep recent/active errors in main file

### Example Entry

```markdown
## ERR-001: Program Freezes on Startup

**Date**: 2024-12-05  
**Severity**: High  
**Status**: ✅ FIXED

### Description
Application freezes upon startup, preventing access to menu.

### Root Cause
Infinite loop in initialization due to missing null check.

### Impact
Users cannot use the program.

### Solution
Added null check before loop: `if ([string]::IsNullOrWhiteSpace($input)) { exit 0 }`

### Testing
Tested with 10 scenarios including empty input, all passed.

### Files Modified
- run.bat
- implementation.ps1
```

---

## 📚 Quick Reference

### Settings File Template
```ini
[General]
debug_mode=false
timeout_seconds=300
auto_cleanup=true
verbose_output=false

[Logging]
log_input=true
log_important=true
log_error=true
log_output=true
log_debug=false

[Advanced]
# Program-specific settings
```

### Common PowerShell Patterns

**Load Settings**:
```powershell
function Get-Setting($key, $default) {
    if ($settings.ContainsKey($key)) { return $settings[$key] }
    return $default
}
```

**Safe Input Reading** (REQUIRED PATTERN):
```powershell
# ALWAYS wrap Read-Host to handle piped input
function Get-UserInput($prompt) {
    try {
        $input = Read-Host -Prompt $prompt
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "[INFO] Empty input, exiting gracefully"
            return $null
        }
        return $input
    } catch {
        Write-Host "[INFO] Input stream ended, exiting"
        return $null
    }
}

# Usage in main loop
while ($true) {
    $choice = Get-UserInput "Enter choice"
    if ($null -eq $choice) { exit 0 }
    # ... process choice
}
```

**Cleanup Handler**:
```powershell
function Invoke-Cleanup {
    if ($script:cleanupExecuted) { return }
    $script:cleanupExecuted = $true
    Remove-Item run_space\*.tmp -ErrorAction SilentlyContinue
}

# Register Ctrl+C handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Invoke-Cleanup }
try { [Console]::TreatControlCAsInput = $false } catch {}
```

**Timeout Tracking**:
```powershell
$startTime = Get-Date
$timeoutSeconds = [int](Get-Setting "timeout_seconds" "300")

while ($true) {
    if ($timeoutSeconds -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -gt $timeoutSeconds) {
        Write-Host "[ERROR] Timeout exceeded ($timeoutSeconds seconds)"
        exit 1
    }
    # ... main loop logic
}
```

### Testing Checklist

Before marking program complete:
- ✅ **ALL tests run in `_debug/automated_testing_environment/`**
- ✅ Announced test runs in chat before execution
- ✅ Test basic operations with piped input
- ✅ Test with empty/invalid input (pipe exhaustion)
- ✅ Test timeout enforcement
- ✅ Test Ctrl+C cleanup
- ✅ Verify all logs created correctly in test env
- ✅ Check exit codes (0 for success)
- ✅ Verify no temp files left behind
- ✅ Test with missing settings file
- ✅ Test debug mode features
- ✅ Document any issues in ERROR_TRACKING.md
- ✅ **Never ran program from root directory during testing**