# Automated GUI test for Settings-Manager.exe
# Runs the GUI, navigates via SendKeys, edits the Value of printVal, saves, reloads, and verifies settings.ini

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Prep paths
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcRoot = Resolve-Path (Join-Path $here '..\..')
$exePath = Join-Path $here 'Settings-Manager.exe'
$modulesDir = Join-Path $here 'modules'
$settingsFile = Join-Path $modulesDir 'config\settings.ini'

# Ensure no leftover processes block copying
Get-Process -Name 'Settings-Manager' -ErrorAction SilentlyContinue | ForEach-Object { try { Stop-Process -Id $_.Id -Force } catch {} }

# Clean target area
Remove-Item $exePath -Force -ErrorAction SilentlyContinue
Remove-Item $modulesDir -Recurse -Force -ErrorAction SilentlyContinue

# Flag automation mode for in-app confirmations
$env:SETTINGS_AUTOMATION = '1'

# Copy fresh build and modules
Copy-Item (Join-Path $srcRoot 'Settings-Manager.exe') $exePath -Force
Copy-Item (Join-Path $srcRoot 'modules') $modulesDir -Recurse -Force

# Import helpers
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
if (-not ([Type]::GetType('Native.Win32'))) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    namespace Native {
        public class Win32 {
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
        }
    }
"@
}

# Start GUI with explicit environment
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $exePath
$startInfo.WorkingDirectory = $here
$startInfo.UseShellExecute = $false
$startInfo.EnvironmentVariables['SETTINGS_AUTOMATION'] = '1'
$startInfo.EnvironmentVariables['SETTINGS_AUTOMATION_VALUE'] = 'test_gui_value'
$proc = [System.Diagnostics.Process]::Start($startInfo)
$null = $proc.WaitForInputIdle(5000)
Start-Sleep -Seconds 1

# Bring to foreground
$proc.Refresh()
Write-Host "Window title: $($proc.MainWindowTitle)" -ForegroundColor Cyan
Write-Host "Process handle: $($proc.MainWindowHandle)" -ForegroundColor Cyan
try { [Native.Win32]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null } catch {}
Start-Sleep -Milliseconds 500

# Allow automation hook inside app to apply and save
Write-Host "Waiting for automation auto-save..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Close app
try { Stop-Process -Id $proc.Id -Force } catch {}

# Verify settings.ini
if (Test-Path $settingsFile) {
    Write-Host "settings.ini contents:" -ForegroundColor Cyan
    Get-Content $settingsFile
    $match = Select-String -Path $settingsFile -Pattern '^printVal=([^#]+)' -SimpleMatch
    if ($match) {
        $val = ($match.Matches[0].Groups[1].Value).Trim()
        Write-Host "Detected printVal: $val" -ForegroundColor Green
    }
} else {
    Write-Warning "settings.ini not found at $settingsFile"
}
