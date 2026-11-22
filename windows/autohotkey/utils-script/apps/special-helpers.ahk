; Helpers for the launchers in special-launchers.ahk
#Include ..\core\config.ahk

; First path in WezTermPaths that exists, or "" if there is none
FindWezTermPath() {
  for _, path in WezTermPaths {
    if FileExist(path)
      return path
  }
  return ""
}

; WezTermPaths as a bullet list, for error messages
WezTermPathsList() {
  pretty := ""
  for line in WezTermPaths
    pretty .= "∙ " line "`n"
  return pretty
}

onWezTermTertiaryStart(hwnd := 0) {
  script := FindUp(ConfigDirName, "scripts\vctabs.ps1")
  if !script {
    MsgBox "Could not find scripts\vctabs.ps1 above " ConfigDirName
    return
  }

  guiHwnd := WinExist("WezTerm - tertiary ahk_exe wezterm-gui.exe")
  cli := RegExReplace(WinGetProcessPath(guiHwnd), "[^\\]+$", "wezterm.exe")

  cmd := Format(
    'pwsh -NoProfile -File "{}" -Wez "{}" -GuiPid {} -Title "WezTerm - tertiary"',
    script, cli, WinGetPID(guiHwnd)
  )
  Run(cmd)
}
