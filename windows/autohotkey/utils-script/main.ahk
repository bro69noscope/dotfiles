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

#Include streaming-ahk\config\hotkeys_map.ahk
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
Hotkey(HK["bro_hk_ahk__toggle_mouse_pos_overlay"], (*) => ToggleMousePosOverlay())
Hotkey(HK["bro_hk_ahk__clip_and_open_nvim_scratch"], (*) => ClipAndOpenNvimScratch())

HotIf (*) => WinActive("ahk_exe deadlock.exe")
Hotkey(HK["bro_hk_ahk__launch_deadlock_movement_script"], (*) =>
  LaunchDeadLockMovementScript())
HotIf

Hotkey(HK["bro_hk_ahk__move_active_window_right"], (*) => MoveActiveWindowRight())
Hotkey(HK["bro_hk_ahk__move_active_window_left"], (*) => MoveActiveWindowLeft())

Hotkey(HK["bro_hk_ahk__small_page_scroll_up"], (*) => SmallPageScrollMove(1))
Hotkey(HK["bro_hk_ahk__small_page_scroll_down"], (*) => SmallPageScrollMove(-1))
Hotkey(HK["bro_hk_ahk__page_scroll_up"], (*) => SmallPageScrollMove(1, 1))
Hotkey(HK["bro_hk_ahk__page_scroll_down"], (*) => SmallPageScrollMove(-1, 1))

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
Hotkey(HK["bro_hk_ahk__activate_leader_key"], (*) => ActivateLeaderKey())
HotIf

; ========================================
; Keyboard-specific hotkeys - any non-Glove80 keyboard, also excluding games
; ========================================
NonGlove80RemapsEnabled := false

NonGlove80Remaps := Map(
  "CapsLock", "Esc",
  "Esc", "CapsLock",
  "!j", "Down",
  "!k", "Up",
  "!h", "Left",
  "!l", "Right"
)

HotIf (*) => !ExcludeGame() && NonGlove80RemapsEnabled
for src, dst in NonGlove80Remaps
  Hotkey(src, MakeKeySender(dst))
HotIf

PromptNonGlove80Remaps() {
  global NonGlove80RemapsEnabled
  if (CurrentKeyboard = "glove")
    return
  msg := "Non-Glove80 keyboard detected.`n"
    . "Enable non-Glove80 remappings?`n`n"
    . "(vim-style arrow keys on Alt+hjkl, and CapsLock <-> Esc swap)"
  answer := MsgBox(msg, "Keyboard remaps", "YesNo Icon?")
  NonGlove80RemapsEnabled := (answer = "Yes")
}

; =======================================
; STARTUP / SHUTDOWN
; =======================================
DetectAndSetKeyboard()
PromptNonGlove80Remaps()
LoadWindowIDs()
LoadChromeWindowList()
VerifyWindowIDs()
StartStreamingAhk()

OnExit((*) => (
  WriteWindowIDs(),
  SaveChromeWindowList()
))
