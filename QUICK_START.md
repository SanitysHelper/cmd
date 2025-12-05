# Quick Start Guide - Universal Code Executor

## 30-Second Quick Start

1. **Double-click `CodeExecutor.exe`**
2. **Paste your code** or **drag a file onto the window**
3. **Click "Compile & Run"**
4. **See output!**

---

## Step-by-Step Examples

### Example 1: Run C Code

**Step 1: Copy this code**
```c
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

**Step 2: Open CodeExecutor.exe**

**Step 3: Paste the code into the text box**

**Step 4: Click "Compile & Run"**

**Expected Output:**
```
[OUTPUT]
Hello, World!
```

---

### Example 2: Drag & Drop a Python File

**Step 1: Create a file `hello.py` with:**
```python
print("Hello from Python!")
x = 5 + 3
print(f"5 + 3 = {x}")
```

**Step 2: Open CodeExecutor.exe**

**Step 3: Drag `hello.py` onto the window**

**Step 4: Click "Compile & Run"**

**Expected Output:**
```
[OUTPUT]
Hello from Python!
5 + 3 = 8
```

---

### Example 3: PowerShell Script

**Step 1: Copy this code**
```powershell
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Current time: $date"
$sum = (1..5 | Measure-Object -Sum).Sum
Write-Host "Sum of 1-5: $sum"
```

**Step 2: Paste into CodeExecutor**

**Step 3: Click "Compile & Run"**

**Expected Output:**
```
[OUTPUT]
Current time: 2025-12-05 14:23:45
Sum of 1-5: 15
```

---

### Example 4: JavaScript with Node.js

**Step 1: Copy this code**
```javascript
console.log("Hello from JavaScript!");
const numbers = [2, 4, 6, 8, 10];
const sum = numbers.reduce((a, b) => a + b, 0);
console.log("Sum:", sum);
```

**Step 2: Paste into CodeExecutor**

**Step 3: Click "Compile & Run"**

**Expected Output:**
```
[OUTPUT]
Hello from JavaScript!
Sum: 30
```

---

## What to Do If...

### "Language not detected"
- Click the **"Detect"** button
- Make sure your code has language-specific keywords
- For Python: use `print(`, `import`, or `def`
- For C/C++: use `#include`
- For PowerShell: use `Write-Host` or `$`

### "Compilation failed"
- Check that compilers are installed (see Installation section below)
- For C/C++: Install MinGW
- For Python: Python should be in PATH
- For Node.js: Download from nodejs.org

### "Module not found"
Make sure you have the right tools installed:

**Windows Command:**
```batch
REM Check Python
python --version

REM Check Node
node --version

REM Check C compiler
gcc --version
g++ --version
```

---

## Installation Checklist

- [ ] Install `CodeExecutor.exe`
- [ ] (Optional) Install MinGW for C/C++
- [ ] (Optional) Install Python and add to PATH
- [ ] (Optional) Install Node.js and add to PATH
- [ ] Test with a simple program

---

## Keyboard Shortcuts

- `Ctrl+A` in editor: Select all code
- `Ctrl+C` in editor: Copy
- `Ctrl+V` in editor: Paste

---

## Tips & Tricks

1. **Save your work**: Use "Open File" and "Save Output" to manage code
2. **Reuse code**: The editor keeps your last code - just edit it
3. **Test quickly**: Write a small test first before running large programs
4. **Check output**: Scroll in the output box to see all results
5. **Clear often**: Use "Clear" button to reset everything

---

## Common Programs to Test

### Test Python Installation
```python
import sys
print(f"Python version: {sys.version}")
print("Python is working!")
```

### Test C Compiler
```c
#include <stdio.h>
int main() {
    for (int i = 1; i <= 5; i++) {
        printf("%d ", i);
    }
    printf("\n");
    return 0;
}
```

### Test PowerShell
```powershell
Get-Process | Where-Object {$_.Name -like "*cmd*"} | Select-Object Name, CPU
```

### Test JavaScript
```javascript
console.log("Test 1: " + (2+2));
console.log("Test 2: " + (10*5));
```

---

## Need Help?

1. **Check the README** - Full documentation
2. **Recompile** - Run `compile.bat` to rebuild
3. **Check installations** - Verify tools are in PATH
4. **Use Simple Code** - Test with basic "Hello World" programs first

---

**Happy Coding!** 🚀
