SplitPath(A_LineFile, , &ConfigDirName)
SplitPath(ConfigDirName, &ProjectDirName)
global ProjectDirName := ProjectDirName
global ConfigDirName := ConfigDirName

global StartMenuPathProgramData :=
  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

global StartMenuPathRoaming :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\"

global ObsProductionRemoteDebugArgs :=
  " --remote-debugging-port=9222 --remote-allow-origins=http://localhost:9222"

global ObsFtpRemoteDebugArgs :=
  " --remote-debugging-port=9223 --remote-allow-origins=http://localhost:9223"

global StreamingProgramsPath := "C:\Users\ville\myfiles\streaming-programs\"

global WezTermPaths := [
  "C:\Users\ville\myfiles\git-repos\wezterm\target\release\wezterm-gui.exe",
  "C:\Users\ville\scoop\apps\wezterm-nightly\current\wezterm-gui.exe",
  "C:\Users\ville\scoop\shims\wezterm-gui.exe"
]

global StreamingRepoPath :=
  "C:\Users\ville\myfiles\git-repos\next-level-live-streaming\"
