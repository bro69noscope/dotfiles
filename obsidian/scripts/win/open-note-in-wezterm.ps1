param([string]$Path)

$proc = Get-Process wezterm-gui |
  Where-Object { $_.MainWindowTitle -like '*WezTerm - primary*' } |
  Select-Object -First 1

if (-not $proc) {
  wezterm start --class primary -- nvim "$Path"   # no primary running: start one
  return
}

$env:WEZTERM_UNIX_SOCKET = "$HOME\.local\share\wezterm\gui-sock-$($proc.Id)"
wezterm cli spawn -- nvim "$Path"

(New-Object -ComObject WScript.Shell).AppActivate($proc.Id) | Out-Null
