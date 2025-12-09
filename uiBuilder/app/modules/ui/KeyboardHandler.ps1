# ============================================================================
# KEYBOARD INPUT HANDLER - C# BACKEND
# ============================================================================
# Compiles and uses C# for proper keyboard input detection

$script:keyboardHandlerPath = "$PSScriptRoot\KeyboardInput.cs"
$script:keyboardExePath = "$PSScriptRoot\KeyboardInput.exe"
$script:InjectedKeyQueue = @()

function Convert-InjectStringToKey {
    param([string]$Inject)
    if ([string]::IsNullOrWhiteSpace($Inject)) { return $null }

    $vk = 0; $ch = 0; $down = $true; $state = 0; $repeat = 1
    foreach ($part in $Inject -split ';') {
        $kv = $part.Split('=')
        if ($kv.Count -ne 2) { continue }
        $k = $kv[0].Trim().ToLower(); $v = $kv[1].Trim()
        switch ($k) {
            'vk' { [void][int]::TryParse($v, [ref]$vk) }
            'char' { [void][int]::TryParse($v, [ref]$ch) }
            'down' { $down = ($v -eq '1' -or $v -eq 'true') }
            'state' { [void][uint32]::TryParse($v, [ref]$state) }
            'repeat' { [void][uint16]::TryParse($v, [ref]$repeat) }
        }
    }

    return [PSCustomObject]@{
        VirtualKeyCode = [int]$vk
        Character = [char]$ch
        IsKeyDown = [bool]$down
        ControlKeyState = [uint32]$state
        IsShift = ($state -band 0x0012) -ne 0
        IsCtrl = ($state -band 0x000C) -ne 0
        IsAlt = ($state -band 0x0021) -ne 0
        RepeatCount = [uint16]$repeat
        Display = "InjectedKey"
    }
}

function Add-InjectedKey {
    param(
        [int]$VirtualKeyCode,
        [int]$Char = 0,
        [bool]$IsDown = $true,
        [uint32]$ControlKeyState = 0,
        [uint16]$RepeatCount = 1
    )
    $script:InjectedKeyQueue += [PSCustomObject]@{
        VirtualKeyCode = [int]$VirtualKeyCode
        Character = [char]$Char
        IsKeyDown = [bool]$IsDown
        ControlKeyState = [uint32]$ControlKeyState
        IsShift = ([uint32]$ControlKeyState -band 0x0012) -ne 0
        IsCtrl  = ([uint32]$ControlKeyState -band 0x000C) -ne 0
        IsAlt   = ([uint32]$ControlKeyState -band 0x0021) -ne 0
        RepeatCount = [uint16]$RepeatCount
        Display = "InjectedKey"
    }
}

function Compile-KeyboardHandler {
    if (Test-Path $script:keyboardExePath) {
        return $true  # Already compiled
    }
    
    if (-not (Test-Path $script:keyboardHandlerPath)) {
        Write-Host "[ERROR] KeyboardInput.cs not found at $script:keyboardHandlerPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[INFO] Compiling keyboard handler..." -ForegroundColor Cyan
    
    $csc = @(
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\Roslyn\csc.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\Roslyn\csc.exe",
        "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
        "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $csc) {
        Write-Host "[ERROR] C# compiler (csc.exe) not found" -ForegroundColor Red
        return $false
    }

    & $csc -out:$script:keyboardExePath -target:exe $script:keyboardHandlerPath 2>&1 | Out-Null
    
    if (Test-Path $script:keyboardExePath) {
        Write-Host "[OK] Keyboard handler compiled successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERROR] Failed to compile keyboard handler" -ForegroundColor Red
        return $false
    }
}

function Get-KeyboardInput {
    <#
    .DESCRIPTION
    Wait for keyboard input using C# for better detection.
    Returns object with: VirtualKeyCode, Character, IsKeyDown, ControlKeyState, IsShift, IsCtrl, IsAlt
    #>
    
    # 1) If injected queue has items, use them first (for automation)
    if ($script:InjectedKeyQueue.Count -gt 0) {
        $key = $script:InjectedKeyQueue[0]
        if ($script:InjectedKeyQueue.Count -gt 1) {
            $script:InjectedKeyQueue = $script:InjectedKeyQueue[1..($script:InjectedKeyQueue.Count - 1)]
        } else {
            $script:InjectedKeyQueue = @()
        }
        return $key
    }

    # 2) If env var is present, honor it before invoking the C# helper
    $envKey = $env:UIB_INJECT_KEY
    $parsedEnvKey = Convert-InjectStringToKey -Inject $envKey
    if ($parsedEnvKey) { return $parsedEnvKey }

    if (-not (Test-Path $script:keyboardExePath)) {
        if (-not (Compile-KeyboardHandler)) {
            # Fallback to PowerShell if compilation fails
            return Get-KeyboardInputFallback
        }
    }
    
    try {
        # Spawn the C# helper with a timeout so we never hang waiting for input
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $script:keyboardExePath
        $psi.ArgumentList.Add("wait")
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        if (-not $proc.WaitForExit(1500)) {
            try { $proc.Kill() } catch {}
            return Get-KeyboardInputFallback
        }
        $stdout = $proc.StandardOutput.ReadToEnd()
        $output = $stdout -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if (-not $output -or $output.Count -eq 0) {
            return Get-KeyboardInputFallback
        }

        $result = @{}
        foreach ($line in $output) {
            if ($line -match "^(.+?):(.+)$") {
                $key = $matches[1]
                $value = $matches[2]
                switch ($key) {
                    'VK' { $result.VirtualKeyCode = [int]$value }
                    'Char' { $result.Character = [char]$value }
                    'IsDown' { $result.IsKeyDown = [bool]::Parse($value) }
                    'State' { $result.ControlKeyState = [uint]$value }
                    'Display' { $result.Display = $value }
                }
            }
        }

        if (-not $result.ContainsKey('VirtualKeyCode')) {
            return Get-KeyboardInputFallback
        }

        # Add convenience properties
        $result.IsShift = ($result.ControlKeyState -band 0x0012) -ne 0
        $result.IsCtrl = ($result.ControlKeyState -band 0x000C) -ne 0
        $result.IsAlt = ($result.ControlKeyState -band 0x0021) -ne 0

        return [PSCustomObject]$result
    } catch {
        return Get-KeyboardInputFallback
    }
}

function Get-KeyboardInputFallback {
    <#
    .DESCRIPTION
    Fallback to PowerShell keyboard input if C# compilation fails.
    #>
    # Try .NET Console first (more reliable in ConPTY / integrated terminals)
    try {
        $cki = [Console]::ReadKey($true)
        $state = [uint32]0
        if ($cki.Modifiers -band [ConsoleModifiers]::Shift) { $state = $state -bor 0x0012 }
        if ($cki.Modifiers -band [ConsoleModifiers]::Control) { $state = $state -bor 0x000C }
        if ($cki.Modifiers -band [ConsoleModifiers]::Alt) { $state = $state -bor 0x0021 }
        return [PSCustomObject]@{
            VirtualKeyCode = [int]$cki.Key
            Character = $cki.KeyChar
            IsKeyDown = $true
            ControlKeyState = $state
            IsShift = ($state -band 0x0012) -ne 0
            IsCtrl = ($state -band 0x000C) -ne 0
            IsAlt = ($state -band 0x0021) -ne 0
            RepeatCount = 1
            Display = $cki.ToString()
        }
    } catch {
        # Final fallback to RawUI (may fail if console mode unsupported)
        try {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $isShift = ($key.ControlKeyState -band 0x0012) -ne 0
            $isCtrl = ($key.ControlKeyState -band 0x000C) -ne 0
            $isAlt = ($key.ControlKeyState -band 0x0021) -ne 0
            return [PSCustomObject]@{
                VirtualKeyCode = $key.VirtualKeyCode
                Character = $key.Character
                IsKeyDown = $key.KeyDown
                ControlKeyState = $key.ControlKeyState
                IsShift = $isShift
                IsCtrl = $isCtrl
                IsAlt = $isAlt
                RepeatCount = 1
                Display = $key
            }
        } catch {
            return $null
        }
    }
}

# Auto-compile on module load if possible
if ($null -eq (Get-Variable -Name keyboardCompileAttempted -Scope script -ErrorAction SilentlyContinue)) {
    $script:keyboardCompileAttempted = $true
    Compile-KeyboardHandler | Out-Null
}
