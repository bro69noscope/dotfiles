param([string]$Wez = 'wezterm.exe', [int]$GuiPid, [string]$Title = '')

$setTitle = "$PSScriptRoot\set-wezterm-title.ps1"

if ($GuiPid) {
  $env:WEZTERM_UNIX_SOCKET = "$HOME\.local\share\wezterm\gui-sock-$GuiPid"
}
$base = 'C:\Users\ville\myfiles\git-repos\next-level-live-streaming\external'
$tabsPerApp = 3
$apps = [ordered]@{
  obs  = 'obs'
  sbot = 'streamerbot'
  deck = 'streamdeck'
}

$tabs = foreach ($app in $apps.Keys) {
  foreach ($n in 1..$tabsPerApp) {
    [pscustomobject]@{
      Name    = if ($n -eq 1) {
        $app
      } else {
        "$app$n"
      }
      Dir     = $apps[$app]
      Lazygit = ($n -eq 1)
    }
  }
}

function Get-StartupCommand($tab) {
  $lines = @()
  if ($Title) {
    $lines += "& '$setTitle' -Title '$Title'"
  }
  $lines += 'istm'
  if ($tab.Lazygit) {
    $lines += 'lazygit'
  }
  $text = $lines -join '; '
  [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($text))
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

foreach ($tab in $tabs) {
  $cwd  = "$base\$($tab.Dir)\version-control\vcdata"
  $pane = & $Wez cli spawn --cwd $cwd -- pwsh -NoExit -EncodedCommand (Get-StartupCommand $tab)
  & $Wez cli set-tab-title --pane-id $pane $tab.Name
}

& $Wez cli kill-pane --pane-id $first
