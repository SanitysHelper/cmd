# Centralized Logging - Quick Reference

## 📁 Logs Location
```
C:\Users\cmand\OneDrive\Desktop\cmd\logs\
```

## 📋 Log Files

### updatingExecutor
- `updatingExecutor_important.log` - Critical events and decisions
- `updatingExecutor_input.log` - User inputs
- `updatingExecutor_terminal.log` - Terminal outputs

## 🔍 How to Access Logs

### View All Logs
```powershell
Get-ChildItem 'C:\Users\cmand\OneDrive\Desktop\cmd\logs'
```

### View Specific Log
```powershell
Get-Content 'C:\Users\cmand\OneDrive\Desktop\cmd\logs\updatingExecutor_important.log'
```

### Monitor Logs in Real-Time
```powershell
Get-Content 'C:\Users\cmand\OneDrive\Desktop\cmd\logs\updatingExecutor_important.log' -Tail 10 -Wait
```

### Find Logs by Pattern
```powershell
Get-ChildItem 'C:\Users\cmand\OneDrive\Desktop\cmd\logs' -Filter "*important*"
```

## 📊 Log Structure

```
cmd/
└── logs/
    ├── updatingExecutor_important.log
    ├── updatingExecutor_input.log
    └── updatingExecutor_terminal.log
```

## 🚀 For New Programs

When adding logging to new programs:

1. Use automatic parent directory detection:
```batch
for %%A in ("%WORKDIR:~0,-1%") do set "PARENT_DIR=%%~dpA"
set "LOG_DIR=%PARENT_DIR%logs"
```

2. Create log files with program prefix:
```batch
set "LOG_MAIN=%LOG_DIR%\programName_main.log"
set "LOG_DEBUG=%LOG_DIR%\programName_debug.log"
```

3. Ensure directory exists:
```batch
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
```

---

**Version**: 1.0  
**Status**: ✅ Active
