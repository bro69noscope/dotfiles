param([string]$Wez = 'wezterm.exe', [int]$GuiPid, [string]$Title = '')

$setTitle = "$PSScriptRoot\set-wezterm-title.ps1"

if ($GuiPid) {
  $env:WEZTERM_UNIX_SOCKET = "$HOME\.local\share\wezterm\gui-sock-$GuiPid"
}
$base = 'C:\Users\ville\myfiles\git-repos\next-level-live-streaming\external'
$tabs = [ordered]@{
  obs   = 'obs'
  obs2  = 'obs'
  sbot  = 'streamerbot'
  sbot2 = 'streamerbot'
  deck  = 'streamdeck'
  deck2 = 'streamdeck'
}

$first = $null
for ($i = 0; $i -lt 20 -and -not $first; $i++) {
  $json = & $Wez cli list --format json 2>$null
  if ($json) {
    $first = (($json -join '') | ConvertFrom-Json)[0].pane_id
  } else {
    Start-Sleep -Milliseconds 250
  }
}

foreach ($name in $tabs.Keys) {
  $cwd  = "$base\$($tabs[$name])\version-control\vcdata"
  if ($Title) {
    $pane = & $Wez cli spawn --cwd $cwd -- pwsh -NoExit -File $setTitle -Title $Title
  } else {
    $pane = & $Wez cli spawn --cwd $cwd
  }
  & $Wez cli set-tab-title --pane-id $pane $name
}

& $Wez cli kill-pane --pane-id $first
