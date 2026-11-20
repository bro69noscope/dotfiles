; Launchers with their own activate or launch flow, not the generic ActivateOrRun
#Include ..\windows\window-helpers.ahk
#Include ..\core\config.ahk
#Include special-helpers.ahk

ActivateAlacritty() {
  SetTitleMatchMode 2
  idMethod := () => FindWinitMainWindow("alacritty.exe")

  hwnd := idMethod()
  if hwnd
    return FocusWindow(hwnd)

  Run("C:\Users\ville\scoop\apps\alacritty\current\alacritty.exe")
  prevHwnd := WinExist("A")
  if !ActivateWhenReady(idMethod, { timeout: 3000, isLaunch: true })
    return false

  ; needs to be focused twice at launch to fix the terminal cursor appearance
  h := idMethod()
  WinActivate(prevHwnd)
  return FocusWindow(h)
}

ActivatePyCharm() {
  SetTitleMatchMode 2
  idMethod := () => WinExist("ahk_exe pycharm64.exe")
  hwnd := idMethod()
  if hwnd
    return FocusWindow(hwnd)

  Loop Files, "C:\Program Files\JetBrains\PyCharm Community Edition*", "D"
  {
    batPath := A_LoopFileFullPath "\bin\pycharm64.exe"
    if FileExist(batPath) {
      Run batPath
      return ActivateWhenReady(idMethod, { timeout: 3000, isLaunch: true })
    }
  }
  MsgBox "Could not find PyCharm executable."
}

ActivateWezTerm(activate := true) {
  winCrit := "Wezterm ahk_exe wezterm-gui.exe"
  idMethod := () => WinExist(winCrit)
  hwnd := idMethod()

  if hwnd {
    if activate
      FocusWindow(hwnd)
    return
  }

  path := FindWezTermPath()
  if !path {
    MsgBox "Could not find WezTerm executable at any known path:`n`n" .
      WezTermPathsList()
    return
  }

  Run path
  opts := { timeout: 2000, isLaunch: true, activate: activate }
  if !ActivateWhenReady(idMethod, opts)
    MsgBox "Could not activate WezTerm window after launching from: " path
}

ActivateWezTermTertiary(activate := true) {
  return ActivateWezTermTitled("WezTerm - tertiary", activate, onWezTermTertiaryStart)
}

ActivateWezTermTitled(title, activate := true, onStart := "") {
  winCrit := title . " ahk_exe wezterm-gui.exe"
  idMethod := () => WinExist(winCrit)
  hwnd := idMethod()

  if hwnd {
    if activate
      FocusWindow(hwnd)
    return
  }

  titleScript := FindUp(ConfigDirName, "scripts\set-wezterm-title.ps1")
  if !titleScript {
    MsgBox "Could not find scripts\set-wezterm-title.ps1 above " ConfigDirName
    return
  }

  Sleep(500)

  path := FindWezTermPath()
  if !path {
    MsgBox (
      "Could not find WezTerm executable at any known path:`n`n" . WezTermPathsList()
      "`n`n check WezTermPaths in " ConfigDirName
    )
    return
  }

  cmd := Format('"{}" start -- pwsh -NoExit -File "{}" -Title "{}"', path,
    titleScript, title)
  Run(cmd)
  opts := { timeout: 8000, onFound: onStart, isLaunch: true, activate: activate }
  if !ActivateWhenReady(idMethod, opts)
    MsgBox "Could not activate '" title "' window after launching from: " path
}

ActivateNeo4j() {
  SetTitleMatchMode 2
  if hwnd := WinExist("neo4j@bolt://localhost:7687")
    FocusWindow(hwnd)
  else if hwnd := WinExist("Neo4j Desktop")
    FocusWindow(hwnd)
  else
    Run "C:\Users\ville\AppData\Local\Programs\Neo4j Desktop\Neo4j Desktop.exe"
}
