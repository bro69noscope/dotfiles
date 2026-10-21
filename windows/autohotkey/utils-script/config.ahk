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

FindUp(startDir, relPath) {
  dir := startDir
  Loop {
    if FileExist(dir "\" relPath)
      return dir "\" relPath
    parent := RegExReplace(dir, "\\[^\\]+$")
    if (parent = dir)
      return ""
    dir := parent
  }
}

pathsFile := FindUp(ConfigDirName, "shared\wezterm-paths.txt")

WezTermPaths := []
if (pathsFile != "") {
  Loop Read pathsFile {
    line := Trim(A_LoopReadLine)
    if (line != "" && SubStr(line, 1, 1) != "#")
      WezTermPaths.Push(line)
  }
}
