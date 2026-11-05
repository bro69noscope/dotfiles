param([Parameter(Mandatory)][string]$Title)

# Sets the USER_SET_WEZTERM_TITLE user var on this pane. format-window-title in .wezterm.lua reads it.
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Title))
[Console]::Write([char]27 + "]1337;SetUserVar=USER_SET_WEZTERM_TITLE=$b64" + [char]7)
