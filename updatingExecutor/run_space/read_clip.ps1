param([string]$TmpPath)
try {
  $txt = Get-Clipboard -Raw
  $txt = $txt.TrimStart([char]0xFEFF)
  if ([string]::IsNullOrWhiteSpace($txt)) {
    "" | Set-Content -Path $TmpPath -Encoding ASCII
    exit 1
  } else {
    $txt | Set-Content -Path $TmpPath -Encoding ASCII
    exit 0
  }
} catch {
  "" | Set-Content -Path $TmpPath -Encoding ASCII
  exit 2
}
