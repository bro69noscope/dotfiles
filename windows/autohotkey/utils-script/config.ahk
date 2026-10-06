; If the next lines fail with "Failed to open file": the streaming repo ahk junction is missing.
; Run: pwsh -File "create-junction.ps1"
#Include streaming-ahk\config.ahk

SplitPath(A_LineFile, , &ConfigDirName)

StartMenuPathProgramData :=
  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathRoaming :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathScoopApps :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Scoop Apps\"

WezTermPaths := [
  "C:\Users\ville\myfiles\git-repos\wezterm\target\release\wezterm-gui.exe",
  "C:\Users\ville\scoop\apps\wezterm-nightly\current\wezterm-gui.exe",
  "C:\Users\ville\scoop\shims\wezterm-gui.exe"
]
