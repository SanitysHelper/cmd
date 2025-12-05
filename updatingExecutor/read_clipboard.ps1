param([string]$OutputFile)

try {
    $txt = Get-Clipboard -Raw
    $txt = $txt.TrimStart([char]0xFEFF)

    if ([string]::IsNullOrWhiteSpace($txt)) {
        "" | Set-Content -Path $OutputFile -Encoding ASCII
        exit 1
    }

    $txt | Set-Content -Path $OutputFile -Encoding ASCII
    exit 0
} catch {
    "" | Set-Content -Path $OutputFile -Encoding ASCII
    exit 2
}
