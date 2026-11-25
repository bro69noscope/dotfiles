param([string]$Path)

$titlesFile = "$PSScriptRoot\..\..\..\windows\shared\wezterm\wezterm-titles.txt"
$titles = Get-Content -Raw $titlesFile | ConvertFrom-StringData

$proc = Get-Process wezterm-gui |
  Where-Object { $_.MainWindowTitle -like "*$($titles.primary)*" } |
  Select-Object -First 1

if (-not $proc) {
  wezterm start --class primary -- nvim "$Path"   # no primary running: start one
  return
}

$env:WEZTERM_UNIX_SOCKET = "$HOME\.local\share\wezterm\gui-sock-$($proc.Id)"
wezterm cli spawn -- nvim "$Path"

(New-Object -ComObject WScript.Shell).AppActivate($proc.Id) | Out-Null
