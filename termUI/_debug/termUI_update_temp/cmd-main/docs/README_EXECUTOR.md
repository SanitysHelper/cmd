# Universal Code Executor - EXE Package

A standalone Windows application for running and compiling code in multiple languages with a user-friendly GUI.

## Features

✅ **Drag & Drop Support** - Drag code files directly into the window to load them
✅ **Automatic Language Detection** - Detects: C, C++, Python, JavaScript, PowerShell, Batch
✅ **One-Click Compilation & Execution** - Compiles and runs code seamlessly
✅ **Live Output Display** - See program output in real-time
✅ **Save Output** - Export execution results to text files
✅ **File Browser** - Open code files through standard file dialog

## Supported Languages

| Language | Extension | Features |
|----------|-----------|----------|
| **C** | `.c` | Compiled via GCC, supports standard I/O |
| **C++** | `.cpp` | Compiled via G++, includes STL support |
| **Python** | `.py` | Interpreted, requires Python installed |
| **JavaScript** | `.js` | Runs via Node.js, requires Node installed |
| **PowerShell** | `.ps1` | Native Windows scripting with full cmdlet support |
| **Batch** | `.bat` | Windows command scripts |

## Usage

### Basic Usage
1. **Double-click** `CodeExecutor.exe` to launch
2. **Paste or drag-drop** your code
3. Click **"Detect"** to auto-detect language (optional - happens on run)
4. Click **"Compile & Run"** to execute
5. View output in the Output panel

### Drag & Drop
1. Open `CodeExecutor.exe`
2. Drag a `.c`, `.cpp`, `.py`, `.js`, `.ps1`, or `.bat` file onto the window
3. Code loads automatically
4. Click "Compile & Run"

### Open From File
1. Click **"Open File"** button
2. Select a code file
3. Code loads into editor
4. Click **"Compile & Run"**

### Save Results
1. After running code, click **"Save Output"**
2. Choose location and filename
3. Output is saved as `.txt`

## Installation Requirements

### Required
- Windows 7 or later
- `.NET Framework 4.0+` (included with Windows)

### Optional (for specific languages)
- **C/C++**: Install [MinGW](https://www.mingw-w64.org/) and add to PATH
- **Python**: Install [Python](https://www.python.org) and add to PATH
- **Node.js**: Install [Node.js](https://nodejs.org) and add to PATH

## Installation Steps

### For C/C++ Support (MinGW)
1. Download MinGW: https://www.mingw-w64.org/
2. Install to `C:\mingw64\` or similar
3. Add to PATH:
   - Press `Win + X` → System
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Add `C:\mingw64\bin` to PATH

### For Python Support
1. Download Python: https://www.python.org
2. During installation, **check "Add Python to PATH"**
3. Verify: Open cmd and type `python --version`

### For JavaScript Support
1. Download Node.js: https://nodejs.org
2. Run installer with default settings
3. Verify: Open cmd and type `node --version`

## Files in Package

```
CodeExecutor.exe           - Main executable
CodeExecutor.cs            - C# source code
compile.bat                - Compilation batch script
compile_executor.bat       - AutoHotkey compiler (if using AHK version)
CodeExecutor.ahk           - AutoHotkey source (alternative)
README.md                  - This file
```

## Building from Source

### Recompile C# Version (Windows)
```batch
cd path\to\cmd\folder
compile.bat
```

Requirements:
- `.NET Framework 4.0+` (default on Windows)

### Alternative: AutoHotkey Version
If you prefer to use the AutoHotkey version:
1. Install AutoHotkey v2.0: https://www.autohotkey.com/
2. Run: `compile_executor.bat`

## Example Code Snippets

### C
```c
#include <stdio.h>

int main() {
    printf("Hello from C!\n");
    int result = 15 + 25;
    printf("15 + 25 = %d\n", result);
    return 0;
}
```

### C++
```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> nums = {10, 20, 30};
    int sum = 0;
    for (int n : nums) sum += n;
    std::cout << "Sum: " << sum << std::endl;
    return 0;
}
```

### Python
```python
print("Hello from Python!")
numbers = [1, 2, 3, 4, 5]
print(f"Sum: {sum(numbers)}")
```

### JavaScript
```javascript
console.log("Hello from Node.js!");
const arr = [1, 2, 3, 4, 5];
const sum = arr.reduce((a, b) => a + b, 0);
console.log("Sum:", sum);
```

### PowerShell
```powershell
$numbers = @(1, 2, 3, 4, 5)
$sum = ($numbers | Measure-Object -Sum).Sum
Write-Host "Sum: $sum"
Get-Date -Format "HH:mm:ss"
```

### Batch
```batch
@echo off
setlocal enabledelayedexpansion
set /a result = 15 + 25
echo 15 + 25 = !result!
```

## Troubleshooting

### Issue: "gcc/g++ not found"
**Solution**: Install MinGW and add to PATH. See "Installation Steps" above.

### Issue: "Python not found"
**Solution**: Install Python and check "Add Python to PATH" during installation.

### Issue: "Node not found"
**Solution**: Install Node.js from https://nodejs.org/

### Issue: Application won't start
**Solution**: 
1. Ensure `.NET Framework 4.0+` is installed
2. Open cmd and verify: `csc.exe --help` should show C# compiler version
3. Try rebuilding: `compile.bat`

### Issue: Language not detected
**Solution**: 
1. Make sure code contains language-specific keywords
2. Click "Detect" button to manually trigger detection
3. Check that extension matches language (`.py` for Python, etc.)

## Features Roadmap

Future versions may include:
- [ ] Syntax highlighting
- [ ] Code templates/snippets
- [ ] Lua, Ruby, Go support
- [ ] Custom compiler flags
- [ ] Debug mode with breakpoints
- [ ] Code formatting
- [ ] Recent files menu

## Testing

A comprehensive test suite is available for all supported languages:

```batch
cd updatingExecutor
test_runner.bat
```

For full testing documentation, see [TESTING.md](updatingExecutor/TESTING.md).

## License

This tool is provided as-is for educational and personal use.

## Support

For issues or feature requests, please contact the developer.

---

**Version**: 1.0  
**Created**: December 2025  
**Platform**: Windows 7+  
**Status**: Stable
