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

# Instructions for New Program Creation

When creating a new program, please follow these guidelines to ensure consistency, maintainability, and ease of debugging:
1. **Single Execution**: Design the program to run only once per invocation. Avoid loops that require manual termination unless explicitly needed for the program's purpose. If so then automate it in debug mode via terminal or someway else. remember debug is found in settings file in 17. You can generate using other languages, such as python or powershell, or even c++, but the main executable must be a Windows batch file (.bat) that orchestrates the execution flow.
2. **Terminal and Executable Integration**: Ensure the program can be executed both from the terminal and as a standalone executable file. Provide clear instructions for both methods of execution.
3. **Workspace Organization**: Create a dedicated workspace directory within your project structure. This directory should house all related files, including source code, configuration files, and documentation.
4. **Logging Mechanisms**: Implement logging mechanisms to capture critical information such as inputs, outputs, and significant events during program execution. Log files should be organized under a designated 'log' subdirectory within the workspace.
    - **Input Logging**: Record all user inputs in an 'input.log' file located within the log directory.
    - **Important Information Logging**: Document crucial program activities and decisions in an 'important.log' file also placed in the log directory.
    - **Terminal Output Logging**: Capture all terminal outputs in a 'terminal.log' file within the log directory, if feasible.
    - **Output Logging**: Document all program outputs in an 'output.log' file within the log directory.
    - **Error Logging**: Document all errors and exceptions in an 'error.log' file within the log directory.
    - **Debugging Logs**: Document all debugging-related information in a 'debug.log' file within the log directory.
    - **General Logging**: Document general program activities in a 'general.log' file within the log directory.
    - **Log Rotation**: Implement log rotation strategies to manage log file sizes and prevent disk space exhaustion. Rotate logs periodically or based on size thresholds.
    - **Log Parsing**: Develop a simple parser to extract useful information from log files, facilitating analysis and troubleshooting.
5. **Executable Placement**: Store all executable files in the same directory as the workspace to facilitate easy access and execution.
6. **Language Management**: Maintain a 'languages' subdirectory within the workspace to organize code files by programming language. Update this directory as new languages are introduced or existing ones are modified.
7. **Documentation**: Include comprehensive comments within the code and provide README files to explain the program's purpose, functionality, and usage instructions. This will aid other developers and AI models in understanding the codebase. Have the main bat file generate a readme file in the workspace on first run that explains the program and its structure.
8. **Functionality Separation**: Structure the code into distinct functions or modules to enhance readability and simplify debugging processes.
9. **Security Considerations**: Prioritize security in your code by implementing best practices to mitigate vulnerabilities and protect against potential threats.
10. **Testing and Debugging**: Rigorously test the code for bugs and errors before delivery. Implement error handling mechanisms to gracefully manage unexpected situations. Add a debug setting to the settings file in 17 and if enabled it will have the program clear everything except the executable and delete workspace on exit.
11. **Timeout Implementation**: Introduce a timeout variable to limit the program's execution duration. This will prevent scenarios where the program runs indefinitely, allowing for automatic termination after a specified period.
By adhering to these guidelines, you will create robust, maintainable, and user-friendly programs that align with best practices in software development.
12. **Version Control**: Use version control systems (e.g., Git) to track changes, manage code versions, and collaborate with other developers effectively.
13. **Consistent Formatting**: Follow consistent code formatting and styling conventions to enhance readability and maintainability across the codebase.
14. **Dependency Management**: Clearly document and manage any external dependencies or libraries required for the program to function correctly.
15. **Performance Optimization**: Consider performance implications and optimize the code for efficiency, especially for resource-intensive operations.
16. **User Feedback**: Provide meaningful feedback to users during program execution, including progress indicators and error messages, to enhance the user experience.
17. **settings File**: If applicable, include a settings file to allow users to customize program behavior without modifying the source code directly. Also add a settings gui as a separate executable that edits the settings file in a user friendly way. Have it open when a settings file isn't found on first run. Also have it run when the user passes a /settings argument to the main executable.
18. **Code Review**: Conduct regular code reviews to identify areas for improvement, catch issues early, and foster knowledge sharing among team members.
19. **Continuous Improvement**: Encourage continuous learning and improvement by regularly reviewing and refining the codebase based on feedback and emerging best practices.
20. **Backup Strategy**: Establish a backup strategy to safeguard important data and code changes, ensuring resilience against accidental loss or corruption.
21. **Termination Handling**: Implement proper termination handling to ensure that resources are released, and the program exits gracefully under various conditions. If I press ctrl c, the program should clean up any temporary files and exit without leaving residual processes running.
22. **Error Reporting**: Develop a mechanism to report errors and exceptions to the user, providing actionable steps they can take to resolve them.
23. **Modularization**: Break down complex functionalities into smaller, modular components to improve code reusability and maintainability.
24. **Cross-Platform Compatibility**: Test the program on different operating systems and architectures to ensure compatibility and portability.
25. **Data Validation**: Validate input data thoroughly to prevent invalid or malicious inputs from causing unintended consequences.
26. **Resource Cleanup**: Ensure that any allocated resources, such as open files or network connections, are properly closed and released when no longer needed.
27. **User Documentation**: Provide user-friendly documentation, including installation guides, usage instructions, and troubleshooting tips, to assist users in effectively utilizing the program.
28. **Automated Testing and enviroment**: Implement automated tests to verify the correctness of the code and facilitate regression testing during future updates. also make a copy of the parent directory of the executable and name it as <originaldirname>_testenv and have the program run in that folder to avoid any interference with existing files.
29. **Configuration Management**: Use configuration files to manage settings and parameters, allowing for easy adjustments without modifying the codebase.
30. **AI Friendly**: Make sure the code is structured in a way that makes it easier for AI models to understand and interact with. This includes clear naming conventions, well-commented code, and adherence to common coding standards.
31. **automatically handle terminal input for testing**: If the program requires terminal input, implement a way to automatically provide this input during testing to facilitate fully automated test runs.
32. **Avoid Global Variables**: Minimize the use of global variables to reduce complexity and make the code more predictable.
33. **Use Standard Libraries**: Leverage standard libraries whenever possible to benefit from established implementations and community support.
34. **Regular Updates**: Regularly update the program with bug fixes, enhancements, and new features to keep it current and relevant.
35. **Feedback Loop**: Establish a feedback loop with users to gather insights about their experiences and incorporate suggestions for improvements.
36. **Secure Coding Practices**: Apply secure coding practices throughout the development process to minimize security risks.
37. **Optimized Resource Usage**: Monitor and optimize resource usage to ensure the program runs efficiently without unnecessary consumption of system resources.
38. **Skip Interactive Prompts During Automated Testing**: When running automated tests, ensure that any interactive prompts are skipped or handled automatically to allow for seamless execution without manual intervention.
38. **Clear Error Messages**: Provide clear and informative error messages that guide users on how to address encountered issues.
39. **Progress Indicators**: Incorporate progress indicators to inform users about the ongoing execution of long-running tasks.
40. **Customizable Behavior**: Allow users to configure certain aspects of the program's behavior through command-line arguments or environment variables.
41. **Robustness Against Errors**: Design the program to recover gracefully from errors and continue executing where possible, rather than crashing abruptly.
42. **Efficient Memory Usage**: Optimize memory usage to prevent excessive memory consumption, which could lead to performance degradation or crashes.

**instructions for editing existing programs**: When modifying existing programs, ensure that you maintain the original structure and conventions outlined above. Document any changes made, including the rationale behind them, to facilitate future maintenance and understanding by other developers or AI models. Test the modified program thoroughly to ensure that new changes do not introduce regressions or unintended side effects. Additionally, consider adding unit tests for critical sections of the code to help catch bugs early during development. **IMPORTANT NOTE:** When editing an existing program that works that we havent worked on yet, make a backup copy of the original program before making any changes. This will allow you to revert to the previous version if the modifications introduce issues or do not function as intended. Name it with a suffix like v.versionnumber (e.g., program_v1.0.bat) and store it in a separate backups folder within the project directory. Ask if I want to make a backup before proceeding with edits. If I say yes, make the backup and proceed with edits. If I say no, just edit the program normally. ask again if I tell you the program works before or you don't know. 

**reporting changes**: After making changes to an existing program, provide a summary of the modifications made, including any new features added, bugs fixed, or performance improvements implemented. This summary should be documented in a changelog file within the project directory to keep track of the program's evolution over time. Do not report outside the parent directory of the program being edited. Only report within the project directory.
## Error Tracking & Fixes

To maintain clarity on issues encountered and solutions implemented, maintain an ERROR_TRACKING.md file in the _debug/ directory of each major module or in the root _debug/ folder.

### Error Tracking Format

Each error entry should contain:

1. **Error ID**: Sequential identifier (ERR-001, ERR-002, etc.)
2. **Date Discovered**: When the issue was first identified
3. **Severity**: High/Medium/Low impact on functionality
4. **User Impact**: How this affects end users
5. **Error Description**: Clear explanation of what went wrong
6. **Root Cause**: Why the error occurred
7. **Solution(s)**: What was tried and what ultimately fixed it
8. **Status**: Current state (✅ FIXED, ⚠️ IN PROGRESS, ❌ REGRESSION, etc.)
9. **Testing Verification**: How the fix was validated
10. **Files Modified**: Which files were changed
11. **Implementation Details**: Code snippets or architectural changes

### Error Tracking Location

- **Location**: <module>/_debug/ERROR_TRACKING.md or root _debug/ERROR_TRACKING.md
- **Naming Convention**: Always use ERROR_TRACKING.md for consistency
- **Update Frequency**: Add entries immediately after discovering and fixing issues
- **Archive**: When file gets large (>1000 lines), archive old entries to ERROR_TRACKING_ARCHIVE_YYYY-MM.md

### When to Track Errors

Track errors when:
- A user reports functionality not working as expected
- Automated testing discovers unexpected behavior
- Code review identifies logical flaws
- Performance issues or bottlenecks discovered
- Integration problems between modules

### Best Practices for Error Tracking

1. **Be Specific**: Describe exactly what failed, not vague statements
2. **Include Reproduction Steps**: Make it easy for others to reproduce if needed
3. **Document Root Cause**: Don't just fix symptoms, understand why it happened
4. **Show Multiple Solutions**: If you tried multiple approaches, document what worked and what didn't
5. **Test Thoroughly**: Verify fix with multiple test cases before marking complete
6. **Keep It Concise**: Use clear structure; readers should understand issue in under 2 minutes
7. **Reference Code**: Show actual code snippets when relevant
8. **Link Related Errors**: If this error is related to ERR-002, cross-reference it
