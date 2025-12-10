<#!
connect.ps1 - Automate SSH login to dev.hostbin.org using stored credential
- Stores password securely (DPAPI) in e.fx after first prompt
- Supports refreshing the stored password via -ResetPassword
- Optional -SkipConnect for dry-run/testing without hitting the host
#>

param(
    [switch]$ResetPassword,
    [switch]$SkipConnect
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $PSCommandPath
$PasswordFile = Join-Path $ScriptDir 'e.fx'
$SshUser = 'josh.ferrie'
$SshHost = 'dev.hostbin.org'

function Ensure-SshAvailable {
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        throw "ssh executable not found on PATH. Install OpenSSH client first."
    }
}

function Get-StoredPassword {
    if (-not (Test-Path $PasswordFile)) { return $null }
    try {
        $raw = Get-Content $PasswordFile -ErrorAction Stop -Encoding ASCII | Out-String
        return ConvertTo-SecureString $raw
    } catch {
        Write-Warning "Stored password could not be read; will prompt for a new one."
        return $null
    }
}

function Save-Password {
    $secure = Read-Host "Enter password for $SshUser@$SshHost" -AsSecureString
    if (-not $secure -or [string]::IsNullOrWhiteSpace([System.Net.NetworkCredential]::new('u',$secure).Password)) {
        throw "Password cannot be empty."
    }
    $export = ConvertFrom-SecureString $secure
    $export | Out-File -FilePath $PasswordFile -Encoding ASCII -Force
    Write-Host "[INFO] Password saved to e.fx (machine/user protected)." -ForegroundColor Green
    return $secure
}

function Get-Password {
    param([switch]$ForcePrompt)
    if ($ForcePrompt) { return Save-Password }
    $stored = Get-StoredPassword
    if ($stored) { return $stored }
    return Save-Password
}

function Invoke-Ssh {
    param([securestring]$SecurePassword)

    $plain = [System.Net.NetworkCredential]::new('u', $SecurePassword).Password
    $sshArgs = @('-o','StrictHostKeyChecking=accept-new',"$SshUser@$SshHost")

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'ssh'
    foreach ($arg in $sshArgs) { [void]$psi.ArgumentList.Add($arg) }
    $psi.RedirectStandardInput = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    $null = $proc.Start()

    # Attempt to pass password via stdin; some OpenSSH builds still require a tty
    $proc.StandardInput.WriteLine($plain)
    $proc.StandardInput.Flush()

    $proc.WaitForExit()
    return $proc.ExitCode
}

try {
    Ensure-SshAvailable

    $securePwd = Get-Password -ForcePrompt:$ResetPassword

    if ($SkipConnect) {
        Write-Host "[INFO] SkipConnect specified; not initiating SSH." -ForegroundColor Cyan
        exit 0
    }

    Write-Host "[INFO] Connecting to $SshUser@$SshHost..." -ForegroundColor Cyan
    $exit = Invoke-Ssh -SecurePassword $securePwd
    if ($exit -ne 0) {
        Write-Warning "ssh exited with code $exit. If prompted for password, the build of ssh may require an interactive TTY."
    }
    exit $exit

} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
