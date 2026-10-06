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

#Include keyboard-detect.ahk
#Include leader-key.ahk
#Include leader-hotkeys.ahk
#Include overlay.ahk
#Include ws.ahk
#Include logger.ahk

MainLogFile := "logs\main.log"
TrimLogFile(MainLogFile, 200000)
LogBlank(MainLogFile)

; ==================================================
; Direct system wide hotkeys binds and remappings
; ==================================================
+^!Home:: ToggleMousePosOverlay()
^\:: ClipAndOpenNvimScratch()

#HotIf WinActive("ahk_exe wezterm-gui.exe")
^;::F13
^,::+F13
#HotIf

#HotIf WinActive("ahk_exe deadlock.exe")
!+^F12:: LaunchDeadLockMovementScript()
#HotIf

; ========================================
; Leader key functionality - available on all keyboards except in excluded games
; =========================================
ExcludedGames := [
  ; "Warcraft III.exe",
  "deadlock.exe",
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

OnExit((*) => (
  WriteWindowIDs(),
  SaveChromeWindowList()
))
