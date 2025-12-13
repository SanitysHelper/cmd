$ErrorActionPreference = "Stop"

function Ensure-Dirs {
    param([string]$Root)
    $bin = Join-Path $Root "_bin"
    $debug = Join-Path $Root "_debug"
    foreach ($d in @($bin,$debug)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }
    $archive = Join-Path $debug "archive"
    if (-not (Test-Path $archive)) { New-Item -ItemType Directory -Path $archive -Force | Out-Null }
}

function Get-Settings {
    param([string]$Path)
    $s = @{ proxy_amount = 500; size_limit_kb = 512; validator_timeout_ms = 1500; thread_amount = 64 }
    try {
        if (Test-Path $Path) {
            $ini = Get-Content $Path -Raw
            if ($ini -match "proxy_amount=(\\d+)") { $s.proxy_amount = [int]$Matches[1] }
            if ($ini -match "size_limit_kb=(\\d+)") { $s.size_limit_kb = [int]$Matches[1] }
            if ($ini -match "validator_timeout_ms=(\\d+)") { $s.validator_timeout_ms = [int]$Matches[1] }
            if ($ini -match "thread_amount=(\\d+)") { $s.thread_amount = [int]$Matches[1] }
        }
    } catch {}
    return $s
}

function Fetch-Url {
    param([string]$Url,[int]$SizeLimitKb=512,[int]$TimeoutSec=5)
    try {
        $prev = $global:ProgressPreference; $global:ProgressPreference = 'SilentlyContinue'
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction SilentlyContinue
        $global:ProgressPreference = $prev
        if ($resp -and $resp.StatusCode -eq 200) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($resp.Content)
            if ($bytes.Length -gt ($SizeLimitKb * 1024)) { return $null }
            return $resp.Content
        }
    } catch {}
    return $null
}

function Parse-ProxiesFromText {
    param([string]$Text)
    if (-not $Text) { return @() }
    $lines = $Text -split "\r?\n"
    return ($lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}:\d+$' })
}

function Test-Proxy {
    param([string]$Proxy,[int]$TimeoutMs)
    try {
        $parts = $Proxy -split ':'
        $ip = $parts[0]
        $port = [int]$parts[1]
        $client = [System.Net.Sockets.TcpClient]::new()
        $async = $client.BeginConnect($ip,$port,$null,$null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs)) { $client.Close(); return $false }
        $client.EndConnect($async); $client.Close(); return $true
    } catch { return $false }
}

function Validate-ProxiesBatch {
    param([string[]]$Batch,[int]$TimeoutMs,[int]$ThreadAmount)
    # Use Python threaded validator for performance and compatibility
    $tmpDir = Join-Path $env:TEMP "proxyHunter"
    if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }
    $inFile = Join-Path $tmpDir "batch.txt"
    $Batch | Set-Content -Path $inFile -Encoding ASCII
    $validator = Join-Path (Join-Path $root "_bin") "validator.py"
    $pythonCmd = "python"
    $args = @($validator, $TimeoutMs, $ThreadAmount, $inFile)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pythonCmd
    $psi.Arguments = ($args -join " ")
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    $p.Start() | Out-Null
    $good = New-Object System.Collections.Generic.List[string]
    $bad = New-Object System.Collections.Generic.List[string]
    $mode = ""
    while (-not $p.HasExited) {
        $line = $p.StandardOutput.ReadLine()
        if ($null -eq $line) { Start-Sleep -Milliseconds 50; continue }
        if ($line -like "PROGRESS*") {
            $parts = $line.Split(' ')
            if ($parts.Length -ge 2) {
                $nums = $parts[1].Split('/')
                if ($nums.Length -eq 2) {
                    $done = [int]$nums[0]
                    $total = [int]$nums[1]
                    $percent = [int](($done / [double]$total) * 100)
                    Write-Progress -Activity "Validating batch ($total)" -Status "Processed: $done / $total" -PercentComplete $percent
                }
            }
            continue
        }
        if ($line -eq "GOOD_START") { $mode = "good"; continue }
        if ($line -eq "GOOD_END") { $mode = ""; continue }
        if ($line -eq "BAD_START") { $mode = "bad"; continue }
        if ($line -eq "BAD_END") { $mode = ""; continue }
        if ($mode -eq "good") { $good.Add($line) }
        elseif ($mode -eq "bad") { $bad.Add($line) }
    }
    # Flush any remaining lines
    while (-not $p.StandardOutput.EndOfStream) {
        $line = $p.StandardOutput.ReadLine()
        if ($line -eq "GOOD_START") { $mode = "good"; continue }
        if ($line -eq "GOOD_END") { $mode = ""; continue }
        if ($line -eq "BAD_START") { $mode = "bad"; continue }
        if ($line -eq "BAD_END") { $mode = ""; continue }
        if ($mode -eq "good") { $good.Add($line) }
        elseif ($mode -eq "bad") { $bad.Add($line) }
    }
    Write-Progress -Activity "Validating batch" -Completed
    return @{ good = $good.ToArray(); bad = $bad.ToArray() }
}

# Public sources (plaintext proxy lists)
$Sources = @(
    "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
    "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks4.txt",
    "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt"
)

# Entry
# Resolve program root (three levels up from buttons/mainUI/*.ps1)
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Ensure-Dirs -Root $root
$bin = Join-Path $root "_bin"
$debug = Join-Path $root "_debug"
$rawPath = Join-Path $bin "proxies_raw.txt"
$validPath = Join-Path $bin "proxies_valid.txt"
$badArchive = Join-Path $debug "archive\bad_proxies.txt"
$settings = Get-Settings -Path (Join-Path $root "settings.ini")

# Logging setup
$logsDir = Join-Path $debug "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
$logPath = Join-Path $logsDir "find_proxies.log"
function Write-Log { param([string]$msg) $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "$ts `t $msg" | Add-Content -Path $logPath -Encoding UTF8 }
Write-Log "Start Find Proxies. settings: proxy_amount=$($settings.proxy_amount), size_limit_kb=$($settings.size_limit_kb), validator_timeout_ms=$($settings.validator_timeout_ms), thread_amount=$($settings.thread_amount)"

Write-Host "Fetching proxies (target=$($settings.proxy_amount), size_limit_kb=$($settings.size_limit_kb))..." -ForegroundColor Cyan
$acc = New-Object System.Collections.Generic.List[string]
$srcIndex = 0
foreach ($src in $Sources) {
    $srcIndex++
    Write-Progress -Activity "Fetching sources" -Status "Source $srcIndex/$($Sources.Count)" -PercentComplete ([int](($srcIndex/[double]$Sources.Count)*100))
    $txt = Fetch-Url -Url $src -SizeLimitKb $settings.size_limit_kb -TimeoutSec 5
    if ($txt) {
        $parsed = Parse-ProxiesFromText -Text $txt
        $len = 0
        if (-not [string]::IsNullOrEmpty($txt)) { $len = $txt.Length }
        Write-Log ("Fetched from {0}: text_len={1}, parsed_count={2}" -f $src, $len, $parsed.Count)
        foreach ($p in $parsed) { $acc.Add($p) }
    } else {
        Write-Log ("Skipped {0} due to size limit or fetch error." -f $src)
    }
}
Write-Progress -Activity "Fetching sources" -Completed

# Deduplicate and cap to proxy_amount
$unique = $acc | Sort-Object -Unique
if ($unique.Count -gt $settings.proxy_amount) { $unique = $unique[0..($settings.proxy_amount-1)] }

if ($unique.Count -eq 0) { Write-Host "No proxies fetched. Try increasing size limit or check network." -ForegroundColor Yellow; return }
$unique | Set-Content -Path $rawPath -Encoding ASCII
Write-Host "Saved $($unique.Count) proxies to $rawPath" -ForegroundColor Green
Write-Log "Saved $($unique.Count) proxies to $rawPath"

# Validate in batches until user stops
Write-Host "Starting validation (timeout_ms=$($settings.validator_timeout_ms), threads=$($settings.thread_amount))..." -ForegroundColor Cyan
if (-not (Test-Path $validPath)) { New-Item -ItemType File -Path $validPath -Force | Out-Null }
if (-not (Test-Path $badArchive)) { New-Item -ItemType File -Path $badArchive -Force | Out-Null }

$batchSize = 100
$offset = 0
while ($offset -lt $unique.Count) {
    $end = [Math]::Min($offset + $batchSize, $unique.Count)
    $batch = $unique[$offset..($end-1)]
    Write-Host "Validating batch: $offset..$([int]$end-1) ($($batch.Count) proxies)" -ForegroundColor DarkCyan
    $res = Validate-ProxiesBatch -Batch $batch -TimeoutMs $settings.validator_timeout_ms -ThreadAmount $settings.thread_amount
    if ($res.good.Count -gt 0) { $res.good | Add-Content -Path $validPath -Encoding ASCII }
    if ($res.bad.Count -gt 0) { $res.bad | Add-Content -Path $badArchive -Encoding ASCII }
    $offset = $end

    # Show summary; emphasize good in green when present
    if ($res.good.Count -gt 0) {
        Write-Host "Batch complete: good=$($res.good.Count), bad=$($res.bad.Count)" -ForegroundColor Green
    } else {
        Write-Host "Batch complete: good=$($res.good.Count), bad=$($res.bad.Count)" -ForegroundColor DarkGray
    }
    Write-Log "Batch complete range=$offset..$([int]$end-1) good=$($res.good.Count) bad=$($res.bad.Count)"

    # Auto-continue in 3 seconds; press 'q' within window to stop
    Write-Host "Auto-continue in 3 seconds... press 'q' to stop" -ForegroundColor Yellow
    for ($t=3; $t -gt 0; $t--) {
        Write-Host "Continuing in $t" -ForegroundColor DarkYellow
        $deadline = (Get-Date).AddSeconds(1)
        while ((Get-Date) -lt $deadline) {
            if ([System.Console]::KeyAvailable) {
                $k = [System.Console]::ReadKey($true)
                if ($k.KeyChar -eq 'q') { Write-Host "Stopping." -ForegroundColor Yellow; break 3 }
            }
            Start-Sleep -Milliseconds 50
        }
    }
}

Write-Host "Validation finished. Good proxies saved to $validPath" -ForegroundColor Green
Write-Log "Validation finished. valid_path=$validPath bad_archive=$badArchive"
