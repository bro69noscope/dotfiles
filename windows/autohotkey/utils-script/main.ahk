; ==================================================
; U wanna use computer fast ? yeeeeeeepeediipee wooooh buddy less go
; (AutoHotkey v2)
; ==================================================

#SingleInstance Force
A_MaxHotkeysPerInterval := 3000
SendMode "Input"
SetWorkingDir A_ScriptDir ; Consistent starting directory
TraySetIcon "..\icons\utils.png"
#WinActivateForce ; seems to focus "weak" cusor focus after activation sometimes

#Include input\keyboard-detect.ahk
#Include input\leader-key.ahk
#Include input\leader-hotkeys.ahk
#Include ui\overlay.ahk
#Include core\logger.ahk
#Include windows\move-window-to-monitor.ahk

MainLogFile := "logs\main.log"
TrimLogFile(MainLogFile, 200000)
LogBlank(MainLogFile)

StartStreamingAhk() {
  repo := EnvGet("STREAMING_REPO_PATH")
  if !repo
    repo := RegRead("HKCU\Environment", "STREAMING_REPO_PATH", "")
  if !repo {
    MsgBox("STREAMING_REPO_PATH environment variable not set.", "Error", "Iconx")
    return
  }

  script := RTrim(repo, "\") "\external\ahk\main.ahk"
  if !FileExist(script) {
    e := "streaming ahk script not found: '" script "'"
    LogError(e, MainLogFile)
    MsgBox(e, "Error", "Iconx")
    return
  }

  Run('"' A_AhkPath '" "' script '"')
}

; ==================================================
; Direct system wide hotkeys binds and remappings
; ==================================================
^!+Home:: ToggleMousePosOverlay()
^\:: ClipAndOpenNvimScratch()

#HotIf WinActive("ahk_exe deadlock.exe")
^!+F12:: LaunchDeadLockMovementScript()
#HotIf

^!+Right:: MoveActiveWindowRight()
^!+Left:: MoveActiveWindowLeft()

!PgUp:: SmallPageScrollMove(1)
!PgDn:: SmallPageScrollMove(-1)
^PgUp:: SmallPageScrollMove(1, 1)
^PgDn:: SmallPageScrollMove(-1, 1)

; ========================================
; Leader key functionality - available on all keyboards except in excluded games
; =========================================
ExcludedGames := [
  ; "Warcraft III.exe",
  ; "deadlock.exe",
  ; "dota2.exe",
]

ExcludeGame() {
  for exe in ExcludedGames
    if WinActive("ahk_exe " exe)
      return true
  return false
}

#HotIf !ExcludeGame()
$^Space:: ActivateLeaderKey()
#HotIf

; ========================================
; Keyboard-specific hotkeys - only for Keychron Q3, also excluding games
; ========================================
#HotIf !Excludegame() && (currentKeyboard = "keychronQ3")
CapsLock::Esc
Esc::CapsLock
!j::Down
!k::Up
!h::Left
!l::Right
#HotIf

; =======================================
; STARTUP / SHUTDOWN
; =======================================
DetectAndSetKeyboard()
LoadWindowIDs()
LoadChromeWindowList()
VerifyWindowIDs()
StartStreamingAhk()

OnExit((*) => (
  WriteWindowIDs(),
  SaveChromeWindowList()
))
