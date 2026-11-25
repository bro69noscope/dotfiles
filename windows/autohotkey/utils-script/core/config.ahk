; If the next lines fail with "Failed to open file": the streaming repo ahk junction is missing.
; Run: pwsh -File "scripts\create-junction.ps1"
#Include ..\streaming-ahk\config\general_config.ahk

SplitPath(A_LineFile, , &ConfigDirName)

StartMenuPathProgramData :=
  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathRoaming :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\"

StartMenuPathScoopApps :=
  "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Scoop Apps\"

ScoopShims := "C:\Users\ville\scoop\shims\"
ScoopApps := "C:\Users\ville\scoop\apps\"

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

; Returns the non-empty, non-comment (#) lines of the first <relPath> found above this dir
ReadConfigLines(relPath) {
  lines := []
  file := FindUp(ConfigDirName, relPath)
  if (file = "")
    return lines

  Loop Read file {
    line := Trim(A_LoopReadLine)
    if (line != "" && SubStr(line, 1, 1) != "#")
      lines.Push(line)
  }
  return lines
}

WezTermPaths := ReadConfigLines("shared\wezterm\wezterm-paths.txt")

WezTermTitles := Map()
for line in ReadConfigLines("wezterm\wezterm-instance-titles.txt") {
  kv := StrSplit(line, "=", " `t", 2)
  WezTermTitles[kv[1]] := kv[2]
}
