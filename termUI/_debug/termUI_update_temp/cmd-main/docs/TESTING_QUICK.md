# Quick Testing Guide - updatingExecutor

## Run Tests (3 Commands)

### 1. Quick Test (Installed Languages)
```batch
cd updatingExecutor
test_runner.bat
```
✅ Tests Python, PowerShell, Batch  
✅ No setup required  
✅ Fast (~3 seconds)

### 2. Full Test Suite (All Languages)
```batch
cd updatingExecutor\test_scripts
run_all_tests.bat
```
✅ Tests all 7 languages  
⚠️ Requires interpreters installed  
✅ Complete coverage (~10 seconds)

### 3. Individual Test
```batch
cd updatingExecutor\test_scripts
python test_python.py
```
✅ Test specific language  
✅ Direct execution  
✅ Instant feedback

## Test Results

✅ **PASS** - Green output, exit code 0, .tmp file deleted  
❌ **FAIL** - Red output, exit code 1, .tmp file preserved

## Logs

View detailed results:
```batch
type test_scripts\log\integration_test.log
type test_scripts\log\test_results.log
```

## What Gets Tested

Each test verifies:
1. ✅ Language detection
2. ✅ Code execution
3. ✅ Random number generation
4. ✅ File I/O (write/read)
5. ✅ Cleanup on success
6. ✅ Crash resilience (file preserved on error)
7. ✅ Exit codes

## Full Documentation

- **[TESTING.md](updatingExecutor/TESTING.md)** - Complete testing guide
- **[test_scripts/README.md](updatingExecutor/test_scripts/README.md)** - Test file details
- **[BOOT_MENU.md](updatingExecutor/BOOT_MENU.md)** - Interactive testing with run.bat

## Test Coverage

| Language | Installed by Default | Test File |
|----------|---------------------|-----------|
| Python | ✅ Usually | test_python.py |
| PowerShell | ✅ Windows | test_powershell.ps1 |
| Batch | ✅ Windows | test_batch.bat |
| JavaScript | 🔶 Optional | test_javascript.js |
| Ruby | 🔶 Optional | test_ruby.rb |
| Lua | 🔶 Optional | test_lua.lua |
| Shell | 🔶 Optional | test_shell.sh |

## Quick Commands

```batch
# Run all installed
cd updatingExecutor && test_runner.bat

# Run all languages
cd updatingExecutor\test_scripts && run_all_tests.bat

# Test Python only
python updatingExecutor\test_scripts\test_python.py

# Regenerate tests
cd updatingExecutor && generate_test.bat

# View logs
type updatingExecutor\test_scripts\log\integration_test.log

# Clean temp files
del updatingExecutor\test_scripts\*.tmp
```

## Status Check

```batch
# Verify Python
python --version

# Verify PowerShell
pwsh --version

# Verify Node.js (for JavaScript)
node --version

# Verify Ruby
ruby --version

# Verify Lua
lua -v
```

## Expected Output

```
======================================================
Test Runner for updatingExecutor
======================================================

[INFO] Test directory: ...\test_scripts
[INFO] Log file: ...\log\integration_test.log

[TEST 1/3] Python test...
[PASS] Python test passed
[TEST 2/3] PowerShell test...
[PASS] PowerShell test passed
[TEST 3/3] Batch test...
[PASS] Batch test passed

======================================================
Test run complete!
======================================================
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Command not recognized" | Install interpreter |
| PowerShell won't run | Use `pwsh` instead |
| .tmp files not deleted | Normal for crashes (debug feature) |
| Test hangs | Press Ctrl+C, check timeout setting |

---

**Quick Start**: `cd updatingExecutor && test_runner.bat`
