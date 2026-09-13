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

; functions bound to direct hotkeys rather than leader key
!Home:: ToggleMousePosOverlay()
+^!F13:: ActivateOBS(moveChat := true)
+^!F14:: ActivateOBSPortable(profile := "ftp", moveChat := true)
+^!F7:: MoveProductionOBS(direction := "right")
+^!F8:: MoveProductionOBS(direction := "center")
^@:: ClipAndOpenNvimScratch()

#HotIf WinActive("ahk_exe wezterm-gui.exe")
^;::F13
^,::+F13
#HotIf

#HotIf WinActive("ahk_exe deadlock.exe")
!+^F12:: LaunchDeadLockMovementScript()
#HotIf

Excludegames() {
  return !WinActive("ahk_exe dota2.exe")
    && !WinActive("ahk_exe Warcraft III.exe")
    && !WinActive("ahk_exe deadlock.exe")
}

; Leader key functionality - available on all keyboards except in games
#HotIf Excludegames()
$^Space:: ActivateLeaderKey()
#HotIf

; Keyboard-specific hotkeys - only for Keychron Q3, also excluding games
#HotIf Excludegames() && (currentKeyboard = "keychronQ3")
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
