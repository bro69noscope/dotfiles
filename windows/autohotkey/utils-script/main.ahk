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

#Include streaming-ahk\keybinds.ahk
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
  repo := EnvGet("BRO_NLLS_REPO_PATH")
  if !repo
    repo := RegRead("HKCU\Environment", "BRO_NLLS_REPO_PATH", "")
  if !repo {
    MsgBox("BRO_NLLS_REPO_PATH environment variable not set.", "Error", "Iconx")
    return
  }

  script := RTrim(repo, "\") "\external\ahk\main.ahk"
  if !FileExist(script) {
    e := "streaming ahk script not found: '" script "'"
    LogError(e, MainLogFile)
    MsgBox(e, "Error", "Iconx")
    return
  }

  cmd := Format('"{}" "{}"', A_AhkPath, script)
  Run(cmd)
}

; ==================================================
; Direct system wide hotkeys binds and remappings
; ==================================================
; Key strings live in streaming-ahk\keybinds.ahk
Hotkey(Keybinds["ToggleMousePosOverlay"], (*) => ToggleMousePosOverlay())
Hotkey(Keybinds["ClipAndOpenNvimScratch"], (*) => ClipAndOpenNvimScratch())

HotIf (*) => WinActive("ahk_exe deadlock.exe")
Hotkey(Keybinds["LaunchDeadLockMovementScript"], (*) => LaunchDeadLockMovementScript())
HotIf

Hotkey(Keybinds["MoveActiveWindowRight"], (*) => MoveActiveWindowRight())
Hotkey(Keybinds["MoveActiveWindowLeft"], (*) => MoveActiveWindowLeft())

Hotkey(Keybinds["SmallPageScrollUp"], (*) => SmallPageScrollMove(1))
Hotkey(Keybinds["SmallPageScrollDown"], (*) => SmallPageScrollMove(-1))
Hotkey(Keybinds["PageScrollUp"], (*) => SmallPageScrollMove(1, 1))
Hotkey(Keybinds["PageScrollDown"], (*) => SmallPageScrollMove(-1, 1))

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

; Hotkey() cannot remap to a key name (v1 feature), so send the target key instead
MakeKeySender(key) => (*) => Send("{" key "}")

HotIf (*) => !ExcludeGame()
Hotkey(Keybinds["ActivateLeaderKey"], (*) => ActivateLeaderKey())
HotIf

; ========================================
; Keyboard-specific hotkeys - only for Keychron Q3, also excluding games
; ========================================
HotIf (*) => !ExcludeGame() && (currentKeyboard = "keychronQ3")
for src, dst in KeychronQ3Remaps
  Hotkey(src, MakeKeySender(dst))
HotIf

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
