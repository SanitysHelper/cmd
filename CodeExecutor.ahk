; Universal Code Executor - AutoHotkey v2.0
; Allows drag-and-drop code execution with compilation support
; Compile with: ahk2exe /in "CodeExecutor.ahk" /out "CodeExecutor.exe"

#Requires AutoHotkey v2.0

; GUI Setup
MyGui := Gui()
MyGui.Opt("+AlwaysOnTop")
MyGui.Title := "Universal Code Executor"

; Add controls
MyGui.Add("Text",, "Drag & drop code files here or paste code:")
MyGui.Add("Edit", "x10 y30 w780 h300 vCodeEditor", "")
MyGui.Add("Text", "x10 y340 w100", "Detected Language:")
MyGui.Add("Text", "x120 y340 w100 vLangDetect cBlue", "Unknown")
MyGui.Add("Button", "x10 y370 w100 h30", "Detect").OnEvent("Click", DetectLanguage)
MyGui.Add("Button", "x120 y370 w100 h30", "Compile & Run").OnEvent("Click", CompileAndRun)
MyGui.Add("Button", "x230 y370 w100 h30", "Clear").OnEvent("Click", ClearCode)
MyGui.Add("Button", "x340 y370 w100 h30", "Open File").OnEvent("Click", OpenFile)
MyGui.Add("Button", "x450 y370 w100 h30", "Save Output").OnEvent("Click", SaveOutput)
MyGui.Add("Text", "x10 y410 w100", "Output:")
MyGui.Add("Edit", "x10 y430 w780 h200 ReadOnly vOutput", "")

; Make GUI dragable for files
MyGui.OnEvent("DropFiles", DropFilesHandler)

; Show GUI
MyGui.Show("w800 h650")

; Global variables
global DetectedLang := "unknown"
global CompilerPath := {}

; Initialize compiler paths
InitializeCompilers()

InitializeCompilers() {
    CompilerPath.gcc := FindExecutable("gcc")
    CompilerPath.gpp := FindExecutable("g++")
    CompilerPath.python := FindExecutable("python")
    CompilerPath.node := FindExecutable("node")
    CompilerPath.pwsh := FindExecutable("pwsh")
    CompilerPath.cmd := A_ComSpec
}

FindExecutable(name) {
    try {
        ; Try to find in PATH
        result := ""
        try result := ComObjCreate("WScript.Shell").Exec(ComSpec " /c where " name).StdOut.ReadAll()
        if (result != "")
            return Trim(result)
    }
    return ""
}

DropFilesHandler(GuiDropFiles, info) {
    files := StrSplit(info, "`n")
    if (files.Length > 0) {
        filePath := files[1]
        try {
            content := FileRead(filePath)
            MyGui["CodeEditor"].Value := content
            DetectLanguage()
        } catch as err {
            MsgBox("Error reading file: " err.What)
        }
    }
}

DetectLanguage(GuiCtrlObj := "", Info := "") {
    code := MyGui["CodeEditor"].Value
    
    if (code = "") {
        DetectedLang := "unknown"
    } else if (InStr(code, "Write-Host") || InStr(code, "Get-") || InStr(code, "Set-")) {
        DetectedLang := "powershell"
    } else if (InStr(code, "console.log") || InStr(code, "const ") || InStr(code, "function ")) {
        DetectedLang := "javascript"
    } else if (InStr(code, "print(") || InStr(code, "import ") || InStr(code, "def ")) {
        DetectedLang := "python"
    } else if (InStr(code, "#include <iostream>") || InStr(code, "std::") || InStr(code, "#include <vector>")) {
        DetectedLang := "cpp"
    } else if (InStr(code, "#include")) {
        DetectedLang := "c"
    } else if (InStr(code, "@echo off") || InStr(code, "setlocal")) {
        DetectedLang := "batch"
    } else if (InStr(code, "#!/bin/bash") || InStr(code, "#!/bin/sh")) {
        DetectedLang := "bash"
    } else {
        DetectedLang := "unknown"
    }
    
    MyGui["LangDetect"].Value := DetectedLang
}

CompileAndRun(GuiCtrlObj := "", Info := "") {
    code := MyGui["CodeEditor"].Value
    
    if (code = "") {
        MyGui["Output"].Value := "[ERROR] No code to execute!"
        return
    }
    
    DetectLanguage()
    
    ; Create temp directory for execution
    tempDir := A_Temp "\CodeExecutor_" A_TickCount
    DirCreate(tempDir)
    
    try {
        switch DetectedLang {
            case "c":
                ExecuteC(code, tempDir)
            case "cpp":
                ExecuteCPP(code, tempDir)
            case "python":
                ExecutePython(code, tempDir)
            case "javascript":
                ExecuteJavaScript(code, tempDir)
            case "powershell":
                ExecutePowerShell(code, tempDir)
            case "batch":
                ExecuteBatch(code, tempDir)
            case "bash":
                ExecuteBash(code, tempDir)
            default:
                MyGui["Output"].Value := "[ERROR] Unknown language type: " DetectedLang "`n`nSupported: C, C++, Python, JavaScript, PowerShell, Batch, Bash"
        }
    } catch as err {
        MyGui["Output"].Value := "[ERROR] Execution failed: " err.What "`n" err.Extra
    } finally {
        ; Cleanup temp files (keep directory for potential reuse)
        Sleep(500)
    }
}

ExecuteC(code, tempDir) {
    srcFile := tempDir "\code.c"
    exeFile := tempDir "\code.exe"
    
    FileWrite(srcFile, code)
    
    if (CompilerPath.gcc = "") {
        MyGui["Output"].Value := "[ERROR] GCC not found. Install MinGW or add GCC to PATH."
        return
    }
    
    ; Compile
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /c cd " tempDir " && " CompilerPath.gcc " -o code.exe code.c 2>&1", , true)
    compileOutput := exec.StdOut.ReadAll()
    
    if (exec.Status != 0 || InStr(compileOutput, "error")) {
        MyGui["Output"].Value := "[COMPILE ERROR]`n" compileOutput
        return
    }
    
    ; Run
    exec := shell.Exec(exeFile " 2>&1", , true)
    runOutput := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" runOutput
}

ExecuteCPP(code, tempDir) {
    srcFile := tempDir "\code.cpp"
    exeFile := tempDir "\code.exe"
    
    FileWrite(srcFile, code)
    
    if (CompilerPath.gpp = "") {
        MyGui["Output"].Value := "[ERROR] G++ not found. Install MinGW or add G++ to PATH."
        return
    }
    
    ; Compile
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /c cd " tempDir " && " CompilerPath.gpp " -o code.exe code.cpp 2>&1", , true)
    compileOutput := exec.StdOut.ReadAll()
    
    if (exec.Status != 0 || InStr(compileOutput, "error")) {
        MyGui["Output"].Value := "[COMPILE ERROR]`n" compileOutput
        return
    }
    
    ; Run
    exec := shell.Exec(exeFile " 2>&1", , true)
    runOutput := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" runOutput
}

ExecutePython(code, tempDir) {
    srcFile := tempDir "\code.py"
    FileWrite(srcFile, code)
    
    if (CompilerPath.python = "") {
        MyGui["Output"].Value := "[ERROR] Python not found. Install Python and add to PATH."
        return
    }
    
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /c " CompilerPath.python " " srcFile " 2>&1", , true)
    output := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" output
}

ExecuteJavaScript(code, tempDir) {
    srcFile := tempDir "\code.js"
    FileWrite(srcFile, code)
    
    if (CompilerPath.node = "") {
        MyGui["Output"].Value := "[ERROR] Node.js not found. Install Node.js and add to PATH."
        return
    }
    
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /c " CompilerPath.node " " srcFile " 2>&1", , true)
    output := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" output
}

ExecutePowerShell(code, tempDir) {
    srcFile := tempDir "\code.ps1"
    FileWrite(srcFile, code)
    
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec("powershell -NoProfile -ExecutionPolicy Bypass -File " srcFile " 2>&1", , true)
    output := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" output
}

ExecuteBatch(code, tempDir) {
    srcFile := tempDir "\code.bat"
    FileWrite(srcFile, code)
    
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /c " srcFile " 2>&1", , true)
    output := exec.StdOut.ReadAll()
    MyGui["Output"].Value := "[OUTPUT]`n" output
}

ExecuteBash(code, tempDir) {
    srcFile := tempDir "\code.sh"
    FileWrite(srcFile, code)
    
    MyGui["Output"].Value := "[INFO] Bash support requires Windows Subsystem for Linux (WSL)`n`nTo enable: wsl --install"
}

ClearCode(GuiCtrlObj := "", Info := "") {
    MyGui["CodeEditor"].Value := ""
    MyGui["Output"].Value := ""
    MyGui["LangDetect"].Value := "unknown"
    DetectedLang := "unknown"
}

OpenFile(GuiCtrlObj := "", Info := "") {
    try {
        fileSelect := FileSelect(1, , "Open Code File", "All Files (*.*)|C Files (*.c)|C++ Files (*.cpp)|Python Files (*.py)|JavaScript Files (*.js)|PowerShell Files (*.ps1)|Batch Files (*.bat)")
        if (fileSelect != "") {
            content := FileRead(fileSelect)
            MyGui["CodeEditor"].Value := content
            DetectLanguage()
        }
    } catch as err {
        MsgBox("Error: " err.What)
    }
}

SaveOutput(GuiCtrlObj := "", Info := "") {
    try {
        output := MyGui["Output"].Value
        if (output = "") {
            MsgBox("No output to save!")
            return
        }
        
        filePath := FileSelect(2, , "Save Output", "Text Files (*.txt)")
        if (filePath != "") {
            FileWrite(filePath, output)
            MsgBox("Output saved to: " filePath)
        }
    } catch as err {
        MsgBox("Error: " err.What)
    }
}

; Handle window close
MyGui.OnEvent("Close", Close)
Close(GuiObj) {
    ExitApp()
}
