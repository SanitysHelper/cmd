# updatingExecutor - Boot Menu Options

Updated `updatingExecutor/run.bat` now includes a boot menu with options to manage the run_space directory.

## Boot Menu

When you run `run.bat`, you'll see:

```
[BOOT] Script starting...

Choose an action:
[C] Continue normally (default)
[W] Wipe entire run_space directory and exit

Enter choice (C/W):
```

## Options

### [C] Continue normally (default)
- **Action**: Proceed with clipboard reading and script execution
- **When to use**: Normal operation, reading clipboard content
- **Behavior**: 
  - Cleans up old temp files (*.tmp)
  - Ensures helper scripts exist
  - Reads clipboard content
  - Presents menu to run/view/edit clipboard content

### [W] Wipe entire run_space directory and exit
- **Action**: Completely delete all files in `run_space/` and exit
- **When to use**: 
  - Reset the workspace
  - Clean up accumulated temp files and compiled binaries
  - Start fresh
- **Behavior**:
  - Deletes all files in `run_space/`
  - Recreates empty `run_space/` directory
  - Exits immediately (does NOT proceed with script execution)

## Usage Examples

### Continue Normally (Automated)
```batch
:: Press Enter or send 'C' to continue
echo C | run.bat
```

### Wipe and Clean (Automated)
```batch
:: Send 'W' to wipe
echo W | run.bat
```

### Interactive
```batch
:: Run without piped input
run.bat

:: Then respond to the prompt
Enter choice (C/W): C
```

## What Gets Wiped

When you select [W], the following are **permanently deleted**:
- All compiled executables (*.exe)
- All generated source files (main.cpp, etc.)
- All clipboard cache files (clip_input.txt, etc.)
- All saved input files (saved_input.txt)
- All helper script copies
- All temporary files (*.tmp)
- Any other user-created files in run_space

The `run_space/` directory itself is preserved (recreated empty).

## File Structure After Wipe

After selecting [W], run_space will be completely empty until you:
1. Run a module that generates files (clip_run.bat creates main.cpp, save_input.exe)
2. Use clipboard reader (creates clip_input.txt)
3. Run other commands that use the workspace
