; Helpers for the launchers in special-launchers.ahk
#Include ..\core\config.ahk

; NOTE:
; Alacritty/winit briefly creates a WS_EX_NOACTIVATE helper window during startup  that
; also matches "ahk_exe alacritty.exe". That window can never be activated - it's
; explicitly excluded from focus. Filter it out and only match the real top-level
; window: visible, and not marked no-activate.
FindAlacrittyMainWindow() {
  EX_NOACTIVATE := 0x08000000

  for hwnd in WinGetList("ahk_exe alacritty.exe") {
    exStyle := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr")
    if !(exStyle & EX_NOACTIVATE) && DllCall("IsWindowVisible", "ptr", hwnd, "int")
      return hwnd
  }
  return 0
}

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
