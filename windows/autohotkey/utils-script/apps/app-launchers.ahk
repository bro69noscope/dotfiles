#Include ..\windows\window-helpers.ahk
#Include ..\core\config.ahk
#Include ..\windows\chrome-windows.ahk
#Include nvim-scratch\scratch.ahk
#Include special-launchers.ahk

; If the next lines fail with "Failed to open file": the streaming repo ahk junction is
; missing, run: pwsh -File "scripts\create-junction.ps1"
#Include ..\streaming-ahk\window-helpers.ahk
#Include ..\streaming-ahk\stream-apps.ahk

; Normal launchers: each one only calls ActivateOrRun with a window finder (idMethod)
; and a run command. Launchers that need their own activate or launch flow go in
; special-launchers.ahk.

ActivateLosslessCut() {
  idMethod := () => WinExist("ahk_exe LosslessCut.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "LosslessCut.lnk")
}

ActivateStreamDeck(activate := true) {
  idMethod := () => WinExist("ahk_exe StreamDeck.exe")
  opts := { activate: activate }
  return ActivateOrRun(idMethod,
    StartMenuPathProgramData "Elgato\Stream Deck\Stream Deck.lnk",
    opts)
}

ActivateOsu() {
  idMethod := () => WinExist("ahk_exe osu!.exe")
  return ActivateOrRun(idMethod, "C:\Users\ville\AppData\Local\osu!\osu!.exe")
}

ActivateTobiiGhost(activate := true) {
  idMethod := () => WinExist("ahk_exe TobiiGhost.exe")
  opts := { onFound: EnsureFullscreen, activate: activate }
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Tobii\Tobii Ghost.lnk", opts)
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
  return ActivateOrRun(idMethod,
    StartMenuPathRoaming "Steam\Age of Empires II Definitive Edition.url"
  )
}

ActivateBraveBrowser(activate := true) {
  idMethod := () => WinExist("ahk_exe brave.exe")
  opts := { activate: activate }
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Brave.lnk", opts)
}

ActivateBitwarden() {
  idMethod := () => WinExist("ahk_exe Bitwarden.exe")
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Bitwarden.lnk")
}

ActivateSpotify(activate := true) {
  idMethod := () => WinExist("ahk_exe Spotify.exe")
  opts := { activate: activate }
  ; This app is on some bullshit windows store unfindable path
  return ActivateOrRun(idMethod, "spotify.exe", opts)
}

ActivateVSCode() {
  idMethod := () => WinExist("ahk_exe Code.exe")
  return ActivateOrRun(idMethod,
    "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code\Code.exe"
  )
}

ActivateObsidian() {
  idMethod := () => WinExist("ahk_exe Obsidian.exe")
  return ActivateOrRun(idMethod, ScoopApps "obsidian\current\Obsidian.exe")
}

ActivatePowerShell() {
  idMethod := () => WinExist("ahk_exe WindowsTerminal.exe", , StreamingRepoServerName)
  return ActivateOrRun(idMethod, "pwsh")
}

ActivateNotepad() {
  idMethod := () => WinExist("ahk_exe notepad.exe")
  opts := { mousePercent: 94 }
  return ActivateOrRun(idMethod, "notepad.exe", opts)
}

ActivateOneNote() {
  ; class skips transient window
  idMethod := () => WinExist("ahk_exe ONENOTE.EXE ahk_class Framework::CFrame")
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

ActivateDiscord(activate := true) {
  idMethod := () => WinExist("ahk_exe Discord.exe")
  opts := { activate: activate }
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Discord Inc\Discord.lnk", opts)
}

ActivateDota2() {
  idMethod := () => WinExist("ahk_exe dota2.exe")
  return ActivateOrRun(idMethod, StartMenuPathRoaming "Steam\Dota 2.url")
}

ActivateCalculator() {
  idMethod := () => WinExist("Calculator ahk_exe ApplicationFrameHost.exe")
  return ActivateOrRun(idMethod, "calculator:")
}

; Windows gives the path through the version folder (apps\git\2.56.0.4\...), not through the
; "current" junction, so an exact ahk_exe path never matches.
FindGitBashWindow(gitAppDir) {
  for hwnd in WinGetList("ahk_exe mintty.exe") {
    try
      if InStr(WinGetProcessPath(hwnd), gitAppDir) = 1
        return hwnd
  }
  return 0
}

ActivateGitBash() {
  gitAppDir := ScoopApps "git\"
  return ActivateOrRun(() => FindGitBashWindow(gitAppDir), gitAppDir "current\git-bash.exe"
  )
}

ActivateVlc() {
  idMethod := () => WinExist("ahk_exe vlc.exe")
  return ActivateOrRun(idMethod, StartMenuPathScoopApps "VLC media player.lnk")
}

; Auto-Duck owns a hidden "GDI+ Window (Auto-Duck.exe)" helper even when its real window
; is absent
FindAutoDuckWindow() {
  DetectHiddenWindows(true)
  for hwnd in WinGetList("ahk_exe Auto-Duck.exe") {
    if !InStr(WinGetTitle(hwnd), "GDI+ Window")
      return hwnd
  }
  return 0
}

ActivateAutoDuck(activate := true) {
  idMethod := () => FindAutoDuckWindow()
  runCommand :=
    "C:\Users\ville\OneDrive\Streaming\Software settings\AutoDuck\stream_duck.adrt"
  opts := { onFound: (hwnd) => WinShow(hwnd), activate: activate }
  return ActivateOrRun(idMethod, runCommand, opts)
}

ActivateStreamerBot(portableVersion := "", activate := true) {
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

  opts := { activate: activate }
  return ActivateOrRun(idMethod, '"' paths[portableVersion] '"', opts)
}

ActivateZoom() {
  idMethod := () => WinExist(DetectHiddenWindows(true), "ahk_exe Zoom.exe")
  opts := { onFound: (hwnd) => WinShow(hwnd) }
  return ActivateOrRun(idMethod, StartMenuPathProgramData "Zoom\Zoom Workplace.lnk",
    opts)
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

ActivateNeovide() {
  idMethod := () => FindWinitMainWindow("neovide.exe")
  return ActivateOrRun(idMethod, ScoopShims "neovide.exe")
}

QuickSetup(mode := "simple") {
  if mode = "simple" {
    ActivateTobiiGhost(activate := false)
    ActivateObsProduction(moveChat := false, activate := false)
    ActivateAutoDuck(activate := false)
    ActivateBraveBrowser(activate := false)
    ActivateDiscord(activate := false)
    ActivateWezTermPrimary(activate := false)
    ActivateNllsMainServer
  }
  else if mode = "full" {
    ActivateTobiiGhost(activate := false)
    ActivateAutoDuck(activate := false)
    ActivateBraveBrowser(activate := false)
    ActivateDiscord(activate := false)
    ActivateWezTermPrimary(activate := false)
    ActivateWezTermSecondary(activate := false)
    ActivateWezTermTertiary(activate := false)
    ActivateStreamerBot(portableVersion := "production", activate := false)
    ActivateStreamerBot(portableVersion := "ftp", activate := false)
    ActivateStreamFeedApp("left", activate := false)
    ActivateObsProduction(moveChat := false, activate := false)
    ActivateObsPortable(profile := "ftp", moveChat := false, activate := false)
    ActivateObsPortable(profile := "vcam", moveChat := false, activate := false)
    ActivateBrowser1Window(activate := false)
    ActivateBrowser2Window(activate := false)
    ActivateBrowser3Window(activate := false)
    ActivateSpotify(activate := false)
    ActivateNllsMainServer
  }
}
