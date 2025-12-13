function Kill-DependencyLockers {
    param(
        [string[]]$ProcessNames,
        [switch]$Quiet
    )

    if (-not $ProcessNames) { return @() }
    $killed = @()
    foreach ($name in $ProcessNames) {
        try {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                $p.Kill()
                $killed += $p
                if (-not $Quiet) { Write-Verbose "Killed locker process: $($p.ProcessName) (Id=$($p.Id))" }
            }
        } catch {
            if (-not $Quiet) { Write-Verbose ("Failed to kill process {0}: {1}" -f $name, $_) }
        }
    }
    return $killed
}

function Ensure-BinOnPath {
    param(
        [string[]]$Paths,
        [switch]$Quiet
    )

    if (-not $Paths) { return }
    $current = ($env:PATH -split ';')
    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { continue }
        if (-not ($current -contains $p)) {
            $env:PATH = ($current + $p) -join ';'
            $current += $p
            if (-not $Quiet) { Write-Verbose "Added to PATH: $p" }
        }
    }
}

function Test-Dependencies {
    param(
        [string[]]$RequiredPaths = @(),
        [string[]]$RequiredDirectories = @(),
        [string[]]$RequiredExecutables = @(),
        [switch]$FailFast
    )

    $failures = @()

    foreach ($path in $RequiredPaths) {
        if (-not (Test-Path $path)) { $failures += "Missing file: $path" }
    }

    foreach ($dir in $RequiredDirectories) {
        if (-not (Test-Path $dir)) {
            try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch {}
        }
        if (-not (Test-Path $dir)) { $failures += "Missing directory: $dir" }
    }

    foreach ($exe in $RequiredExecutables) {
        if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
            $failures += "Executable not found: $exe"
        }
    }

    if ($failures.Count -gt 0 -and $FailFast) {
        throw "Dependency preflight failed: $($failures -join '; ')"
    }

    return [pscustomobject]@{
        Passed = ($failures.Count -eq 0)
        Failures = $failures
    }
}

function Invoke-DependencyPreflight {
    param(
        [string[]]$RequiredPaths = @(),
        [string[]]$RequiredDirectories = @(),
        [string[]]$RequiredExecutables = @(),
        [string[]]$KillLockers = @(),
        [string[]]$EnsurePath = @(),
        [switch]$FailFast
    )

    if ($KillLockers) { Kill-DependencyLockers -ProcessNames $KillLockers -Quiet }
    if ($EnsurePath) { Ensure-BinOnPath -Paths $EnsurePath -Quiet }
    return Test-Dependencies -RequiredPaths $RequiredPaths -RequiredDirectories $RequiredDirectories -RequiredExecutables $RequiredExecutables -FailFast:$FailFast
}
