function Get-DefaultSettings {
    @{ 
        General = @{ 
            debug_mode = $false
            ui_title = "termUI"
            menu_root = "buttons\mainUI"
            keep_open_after_selection = $true
            show_selected_prompt = $false
        }
        Logging = @{ 
            log_input = $true
            log_input_timing = $true
            log_error = $true
            log_important = $true
            log_menu_frame = $true
            log_transcript = $true
            log_rotation_mb = 5
        }
        Input = @{ 
        }
    }
}

function Merge-Settings {
    param(
        [hashtable]$Defaults,
        [hashtable]$Overrides
    )
    $merged = @{}
    foreach ($key in $Defaults.Keys) {
        if ($Defaults[$key] -is [hashtable]) {
            $override = if ($Overrides.ContainsKey($key)) { $Overrides[$key] } else { @{} }
            $merged[$key] = Merge-Settings -Defaults $Defaults[$key] -Overrides $override
        } else {
            $merged[$key] = $Defaults[$key]
        }
    }
    foreach ($key in $Overrides.Keys) {
        if (-not $merged.ContainsKey($key)) {
            $merged[$key] = $Overrides[$key]
        } elseif ($Overrides[$key] -isnot [hashtable]) {
            $merged[$key] = $Overrides[$key]
        }
    }
    return $merged
}

function Load-IniFile {
    param([string]$Path)
    $data = @{}
    if (-not (Test-Path $Path)) { return $data }
    $section = ""
    foreach ($line in Get-Content $Path) {
        $trim = $line.Trim()
        if (-not $trim -or $trim.StartsWith("#") -or $trim.StartsWith(";")) { continue }
        if ($trim.StartsWith("[") -and $trim.EndsWith("]")) {
            $section = $trim.Trim('[',']')
            if (-not $data.ContainsKey($section)) { $data[$section] = @{} }
            continue
        }
        $pair = $trim.Split("=",2)
        if ($pair.Count -eq 2 -and $section) {
            $key = $pair[0].Trim()
            $val = $pair[1].Trim()
            $data[$section][$key] = $val
        }
    }
    return $data
}

function Normalize-Settings {
    param([hashtable]$Settings)
    # coerce booleans/ints where expected
    $boolKeys = @{
        General = @("debug_mode","keep_open_after_selection","show_selected_prompt")
        Logging = @("log_input","log_input_timing","log_error","log_important","log_menu_frame","log_transcript")
    }
    $intKeys = @{
        Logging = @("log_rotation_mb")
    }
    foreach ($section in $boolKeys.Keys) {
        if (-not $Settings.ContainsKey($section)) { continue }
        foreach ($k in $boolKeys[$section]) {
            if ($Settings[$section].ContainsKey($k)) {
                $Settings[$section][$k] = [bool]::Parse($Settings[$section][$k])
            }
        }
    }
    foreach ($section in $intKeys.Keys) {
        if (-not $Settings.ContainsKey($section)) { continue }
        foreach ($k in $intKeys[$section]) {
            if ($Settings[$section].ContainsKey($k)) {
                $Settings[$section][$k] = [int]$Settings[$section][$k]
            }
        }
    }
    return $Settings
}

function Initialize-Settings {
    param([string]$SettingsPath)
    $defaults = Get-DefaultSettings
    $ini = Load-IniFile -Path $SettingsPath
    $merged = Merge-Settings -Defaults $defaults -Overrides $ini
    $script:settings = Normalize-Settings -Settings $merged
}
