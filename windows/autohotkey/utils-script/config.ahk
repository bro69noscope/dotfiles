SplitPath(A_LineFile, , &ConfigDirName)

ObsExe := "obs64.exe"
StreamerbotExe := "Streamer.bot.exe"
FtpPortableString := "Portable Mode - Profile: ftp"
VcamPortableString := "Portable Mode - Profile: vcam"

StartMenuPathProgramData :=
  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathRoaming :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathScoopApps :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Scoop Apps\"

ObsProductionRemoteDebugArgs :=
  " --remote-debugging-port=9222 --remote-allow-origins=http://localhost:9222"

ObsFtpRemoteDebugArgs :=
  " --remote-debugging-port=9223 --remote-allow-origins=http://localhost:9223"

StreamingProgramsPath := "C:\Users\ville\myfiles\streaming-programs\"

WezTermPaths := [
  "C:\Users\ville\myfiles\git-repos\wezterm\target\release\wezterm-gui.exe",
  "C:\Users\ville\scoop\apps\wezterm-nightly\current\wezterm-gui.exe",
  "C:\Users\ville\scoop\shims\wezterm-gui.exe"
]

StreamingRepoPath :=
  "C:\Users\ville\myfiles\git-repos\next-level-live-streaming\"

StreamingRepoServerName := "MY SERVER"
