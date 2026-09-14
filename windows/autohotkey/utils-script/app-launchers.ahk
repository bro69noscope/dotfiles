#Include window-helpers.ahk
#Include config.ahk
#Include chrome-windows.ahk
#Include nvim-scratch\scratch.ahk

ActivateLosslessCut() {
  idMethod := () => WinExist("ahk_exe LosslessCut.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "LosslessCut.lnk")
}

ActivateStreamDeck() {
  idMethod := () => WinExist("ahk_exe StreamDeck.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Elgato\Stream Deck\Stream Deck.lnk"
  )
}

ActivateOsu() {
  idMethod := () => WinExist("ahk_exe osu!.exe")
  return ActivateOrRun(idMethod, "C:\Users\ville\AppData\Local\osu!\osu!.exe")
}

ActivateTobiiGhost() {
  idMethod := () => WinExist("ahk_exe TobiiGhost.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Tobii\Tobii Ghost.lnk", ,
    ensureFullscreen)
}

ActivateMailClient() {
  idMethod := () => WinExist("ahk_exe olk.exe")
  return ActivateOrRun(idMethod,
    "C:\Users\ville\OneDrive\Desktop\Useful\ahk\Outlook - Shortcut.lnk")
}

ActivateSteam() {
  idMethod := () => WinExist("ahk_exe steamwebhelper.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Steam\Steam.lnk")
}

ActivateAgeOfEmpires2() {
  idMethod := () => WinExist("ahk_exe AoE2DE_s.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Steam\Age of Empires II Definitive Edition.url"
  )
}

ActivateAlacritty() {
  SetTitleMatchMode 2
  idMethod := () => FindAlacrittyMainWindow()

  hwnd := idMethod()
  if hwnd
    return WinActivate(hwnd)

  Run("C:\Users\ville\scoop\apps\alacritty\current\alacritty.exe")
  lastHwnd := WinExist("A")
  if !ActivateWhenReady(idMethod, 3000)
    return false

  ; needs to be focused twice at launch to fix the terminal cursor appearance
  newHwnd := idMethod()
  WinActivate(lastHwnd)
  return WinActivate(newHwnd)
}

ActivateBraveBrowser() {
  idMethod := () => WinExist("ahk_exe brave.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Brave.lnk")
}

ActivateBitwarden() {
  idMethod := () => WinExist("ahk_exe Bitwarden.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Bitwarden.lnk")
}

ActivateSpotify() {
  idMethod := () => WinExist("ahk_exe Spotify.exe")
  return ActivateOrRun(idMethod, "spotify.exe") ; It's some bullshit windows store unfindable path
}

ActivateVSCode() {
  idMethod := () => WinExist("ahk_exe Code.exe")
  return ActivateOrRun(idMethod, "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code\Code.exe"
  )
}

ActivatePowerShell() {
  SetTitleMatchMode 2
  idMethod := () => WinExist("ahk_exe WindowsTerminal.exe")
  return ActivateOrRun(idMethod, "pwsh")
}

ActivateNotepad() {
  idMethod := () => WinExist("ahk_exe notepad.exe")
  return ActivateOrRun(idMethod, "notepad.exe")
}

ActivateOneNote() {
  idMethod := () => WinExist("ahk_exe ONENOTE.EXE")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "OneNote.lnk")
}

ActivateKovaaks() {
  idMethod := () => WinExist("ahk_exe FPSAimTrainer-Win64-Shipping.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Steam\KovaaK 2.0.url")
}

ActivateDeadlock() {
  idMethod := () => WinExist("ahk_exe deadlock.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Steam\Deadlock.url")
}

ActivateDiscord() {
  idMethod := () => WinExist("ahk_exe Discord.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Discord Inc\Discord.lnk")
}

ActivateVlc() {
  idMethod := () => WinExist("ahk_exe vlc.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "VideoLAN\VLC media player.lnk"
  )
}

ActivatePyCharm() {
  SetTitleMatchMode 2
  idMethod := () => WinExist("ahk_exe pycharm64.exe")
  hwnd := idMethod()
  if hwnd
    return WinActivate(hwnd)

  Loop Files, "C:\Program Files\JetBrains\PyCharm Community Edition*", "D"
  {
    batPath := A_LoopFileFullPath "\bin\pycharm64.exe"
    if FileExist(batPath) {
      Run batPath
      return ActivateWhenReady(idMethod, 3000)
    }
  }
  MsgBox "Could not find PyCharm executable."
}

ActivateOBS(moveChat := false) {
  hwnd := 0
  FindOBSWindow() {
    for win in WinGetList("ahk_exe obs64.exe") {
      title := WinGetTitle(win)
      if !InStr(title, "Portable Mode")
        return win
    }
    return 0
  }
  idMethod := () => FindOBSWindow()

  hwnd := idMethod()
  if hwnd {
    WinActivate(hwnd)

    if not moveChat
      return

    if WinExist("Chat ahk_exe Streamer.bot.exe") {
      WinGetPos(&x, &y, &w, &h, hwnd)
      chat := WinExist("Chat ahk_exe Streamer.bot.exe")
      WinActivate(chat)
      WinMove(x + 20, y + 110, 800, 1230, chat)
    }
  } else {
    dir := "C:\Program Files\obs-studio\bin\64bit"
    exe := dir . "\obs64.exe"
    Run('"' exe '"' ObsProductionRemoteDebugArgs, dir)
    ActivateWhenReady(idMethod, 3000)
  }
}

ActivateOBSPortable(profile := "", moveChat := false) {
  FindOBSPortableWindow(profile := "") {
    for win in WinGetList("ahk_exe obs64.exe") {
      title := WinGetTitle(win)
      if InStr(title, "Portable Mode" . (profile ? " - Profile: " profile : ""))
        return win
    }
    return 0
  }
  idMethod := () => FindOBSPortableWindow(profile)

  hwnd := idMethod()
  if hwnd {
    WinActivate(hwnd)

    if not moveChat
      return

    if WinExist("Chat ahk_exe Streamer.bot.exe") {
      WinGetPos(&x, &y, &w, &h, hwnd)
      chat := WinExist("Chat ahk_exe Streamer.bot.exe")
      WinActivate(chat)
      WinMove(x + 20, y + 110, 800, 1230, chat)
    }
  }
  else if profile == "ftp" {
    dir := StreamingProgramsPath "obs-studio-portable-ftp\obs-studio\bin\64bit"

    exe := dir . "\obs64.exe"

    Run('"' exe '" ' ObsFtpRemoteDebugArgs, dir)
    ActivateWhenReady(idMethod, 3000)
  }
  else if profile == "vcam" {
    dir := StreamingProgramsPath "obs-studio-portable-vcam\obs-studio\bin\64bit"

    exe := dir . "\obs64.exe"

    Run('"' exe '" ' ObsFtpRemoteDebugArgs, dir)
    ActivateWhenReady(idMethod, 3000)
  }
  else
    MsgBox "No OBS portable profile specified and no matching window found."
}

MoveProductionOBS(direction := "right") {
  hwnd := 0
  for win in WinGetList("ahk_exe obs64.exe") {
    title := WinGetTitle(win)
    if !InStr(title, "Portable Mode") {
      hwnd := win
      break
    }
  }

  WinGetPos(&x, &y, &w, &h, hwnd)
  if direction = "right"
    WinMove(2560, y, w, h, hwnd)
  else if direction = "center"
    WinMove(0, y, w, h, hwnd)
}

ActivateSreamFeedApp() {
  idMethod := () => WinExist("ahk_exe StreamFeedApp.exe")
  hwnd := idMethod()
  Reposition(hwnd) {
    if WinGetMinMax(hwnd) != 1
      WinRestore(hwnd)

    targetX := -2300
    monIdx := GetMonitorAt(targetX, 0)
    MonitorGetWorkArea(monIdx, &mLeft, &mTop, &mRight, &mBottom)

    width := (mRight - mLeft) // 2 ; half width in case we go back to no fullscreen
    height := mBottom - mTop
    WinMove(mRight - width, mTop, width, height, hwnd)
    EnsureFullscreen(hwnd)
    WinActivate(hwnd)
  }
  if hwnd {
    Reposition(hwnd)
  }
  else {
    Run("dotnet run",
      StreamingRepoPath "external\StreamFeedApp",
      "Min")
    ActivateWhenReady(idMethod, 3000, Reposition)
  }
}

ActivateSreamFeedAppDebug() {
  idMethod := () => WinExist(
    "DevTools - appassets.local/stream-feed.html ahk_exe msedgewebview2.exe")
  hwnd := idMethod()
  if hwnd
    WinActivate(hwnd)
  else {
    hwnd2 := WinExist("ahk_exe StreamFeedApp.exe")
    if hwnd2 {
      WinActivate
      Send "{F12}"
      ActivateWhenReady(idMethod, 3000)
    }
  }
}

ActivateAutoDuck() {
  idMethod := () => (DetectHiddenWindows(true), WinExist("ahk_exe Auto-Duck.exe"))
  return ActivateOrRun(
    idMethod,
    "C:\Users\ville\OneDrive\Streaming\Software settings\AutoDuck\stream_duck.adrt",
    3000,
    (hwnd) => WinShow(hwnd)
  )
}

ActivateStreamerBot(portableVersion := "") {
  paths := Map(
    "production",
    StreamingProgramsPath "streamerbot-portable-production\Streamer.bot\Streamer.bot.exe",
    "ftp",
    StreamingProgramsPath "streamerbot-portable-ftp\Streamer.bot\Streamer.bot.exe"
  )

  FindStreamerBotWindow(version) {
    for win in WinGetList("ahk_exe Streamer.bot.exe") {
      if InStr(WinGetTitle(win), version)
        return win
    }
    return 0
  }
  idMethod := () => FindStreamerBotWindow(portableVersion)

  return ActivateOrRun(idMethod, '"' paths[portableVersion] '"')
}

ActivateWezTerm() {
  winCrit := "Wezterm ahk_exe wezterm-gui.exe"
  idMethod := () => WinExist(winCrit)
  hwnd := idMethod()

  if hwnd
    return WinActivate(hwnd)

  for _, path in WezTermPaths {
    if FileExist(path) {
      Run path
      if ActivateWhenReady(idMethod, 2000)
        return
      else {
        MsgBox "Could not activate WezTerm window after launching from: " path
        return
      }
    }
  }

  pretty := ""
  for line in WezTermPaths
    pretty .= "∙ " line "`n"

  MsgBox "Could not find WezTerm executable at any known path:`n`n" . pretty
}

ActivateWezTermTitled(title) {
  winCrit := title . " ahk_exe wezterm-gui.exe"
  idMethod := () => WinExist(winCrit)
  hwnd := idMethod()

  if hwnd
    return WinActivate(hwnd)

  psCmd := "[Console]::Write([char]27 + ']1337;SetUserVar=WEZTERM_TITLE=' + "
    . "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('" title "')) + [char]7)"

  Sleep(500)

  q := Chr(34)
  for _, path in WezTermPaths {
    if FileExist(path) {
      cmd := q path q " start"
      cmd .= " -- pwsh -NoExit -Command " q psCmd q
      Run(cmd)
      if ActivateWhenReady(idMethod, 8000)
        return
      else {
        MsgBox "Could not activate '" title "' window after launching from: " path
        return
      }
    }
  }

  pretty := ""
  for line in WezTermPaths
    pretty .= "∙ " line "`n"

  MsgBox (
    "Could not find WezTerm executable at any known path:`n`n" . pretty
    "`n`n check WezTermPaths in " ConfigDirName
  )
}

ActivateZoom() {
  idMethod := () => WinExist(DetectHiddenWindows(true), "ahk_exe Zoom.exe")
  return ActivateOrRun(
    idMethod,
    StartMenuPathProgramData "Zoom\Zoom Workplace.lnk",
    3000,
    (hwnd) => WinShow(hwnd)
  )
}

ActivateAdminPowerShell() {
  adminTitle := "Administrator: C:\Program Files\PowerShell\7\pwsh.exe"
  selectAdminTitle := "Select " adminTitle
  idMethod := () => WinExist(adminTitle) || WinExist(selectAdminTitle)
  return ActivateOrRun(idMethod, "*RunAs pwsh.exe")
}

ActivateExplorer() {
  idMethod := () => WinExist("ahk_exe explorer.exe ahk_class CabinetWClass")
  ActivateOrRun(idMethod, "explorer.exe")
}

ActivateNeo4j() {
  SetTitleMatchMode 2
  if WinExist("neo4j@bolt://localhost:7687")
    WinActivate
  else if WinExist("Neo4j Desktop")
    WinActivate
  else
    Run "C:\Users\ville\AppData\Local\Programs\Neo4j Desktop\Neo4j Desktop.exe"
}

ActivateNeovide() {
  idMethod := () => WinExist("ahk_exe neovide.exe")
  return ActivateOrRun(idMethod, "C:\Users\ville\scoop\shims\neovide.exe", 2500)
}

QuickSetup(mode := "simple") {
  if mode = "simple" {
    ActivateTobiiGhost()
    ActivateOBS()
    ActivateAutoDuck()
    ActivateBraveBrowser()
    ActivateDiscord()
    ActivateWezTerm()
  }
  else if mode = "full" {
    ActivateTobiiGhost()
    ActivateAutoDuck()
    ActivateBraveBrowser()
    ActivateDiscord()
    ActivateWezTerm()
    ActivateWezTermTitled("WezTerm - secondary")
    ActivateStreamerBot(portableVersion := "production")
    ActivateStreamerBot(portableVersion := "ftp")
    ActivateSreamFeedApp()
    ActivateOBS()
    ActivateOBSPortable(profile := "ftp")
    ActivateOBSPortable(profile := "vcam")
    ActivateBrowser1Window()
    ActivateBrowser2Window()
    ActivateBrowser3Window()
    ActivateSpotify()
  }
}
