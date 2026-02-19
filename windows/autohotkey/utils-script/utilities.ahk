; ==================================================
; Leader‑Key Window Manager with Chrome Window Tracking
; (AutoHotkey v2)
; ==================================================

#SingleInstance Force
A_MaxHotkeysPerInterval := 3000
SendMode "Input"
SetWorkingDir A_ScriptDir        ; Consistent starting directory
TraySetIcon "..\\icons\\utils.png"

; =======================================
; GLOBALS
; =======================================
; Leader‑key system
global LeaderKeyActive := false
global LeaderKeyBuffer := ""
global LeaderKeyTimeout := 2000

global LeaderCommands := Map(
  ; Single character commands
  "a", ActivateAlacritty,
  "b", ActivateBraveBrowser,
  "d", ActivateDiscord,
  "t", ActivateStreamerBot,
  "k", ActivateKovaaks,
  "l", ActivateDeadlock,
  "n", ActivateNeo4j,
  "o", ActivateOBS,
  "p", ActivatePowerShell,
  "s", ActivateSpotify,
  "v", ActivateVSCode,
  "w", ActivateWezTerm,
  "x", ActivateExplorer,
  "y", ActivatePyCharm,
  "g", ActivateSteam,
  "r", ActivateStreamDeck,
  "m", ActivateMailClient,
  ; Number commands
  "1", ActivateBrowser1Window,
  "2", ActivateBrowser2Window,
  "3", ActivateBrowser3Window,
  ; Symbol commands
  "!", (*) => CaptureCurrentChromeWindow(1),
  "@", (*) => CaptureCurrentChromeWindow(2),
  "#", (*) => CaptureCurrentChromeWindow(3),
  "/", (*) => ReplaceSlashes("/"),
  "\", (*) => ReplaceSlashes("\"),
  ; Multi-character commands
  ".m", WriteMessageDontResendAllCode,
  ".w", WriteMessageWorstUserName,
  "RR", Reload,
  "Spacep", ActivateAdminPowerShell,
  "Space]", ResetChromeWindowList
)


global currentKeyboard := ""

; Window IDs (persisted individually)
global Browser1_ID := 0
global Browser2_ID := 0
global Browser3_ID := 0
global SpotifyWindow_ID := 0

; Chrome‑tracking (persisted as a list)
global ChromeWindowList := []
global ChromeWindowsFile := A_ScriptDir "\\chrome_windows.ini"

; Config file for single‑value IDs
global ConfigFile := A_ScriptDir "\\window_ids.ini"

DetectSpecificKeyboard() {
  keyboards := GetKeyboardInfo()
  detectedKeyboards := []
  for keyboard in keyboards {
    keyboardType := "Unknown"
    ; Check VID/PID in Device ID
    if InStr(keyboard.DeviceID, "VID_3434&PID_0121") {
      keyboardType := "Keychron Q3"
    }
    else if InStr(keyboard.DeviceID, "VID_16C0&PID_27DB") {
      keyboardType := "Glove80"
    }
    ; Only add unique keyboards (avoid duplicates from multiple interfaces)
    found := false
    for existing in detectedKeyboards {
      if (existing = keyboardType) {
        found := true
        break
      }
    }
    if (!found && keyboardType != "Unknown") {
      detectedKeyboards.Push(keyboardType)
    }
  }
  return detectedKeyboards
}

; Get keyboard information via WMI
GetKeyboardInfo() {
  keyboards := []
  for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Keyboard") {
    keyboards.Push({
      Name: objItem.Name,
      Description: objItem.Description,
      DeviceID: objItem.DeviceID,
      PNPDeviceID: objItem.PNPDeviceID
    })
  }
  return keyboards
}

; Run detection once at startup
detectedNames := DetectSpecificKeyboard()

; Show detected keyboard names
for keyboard in detectedNames {
  MsgBox("Detected: " . keyboard)
}

; Set current keyboard variable for hotkeys
for keyboard in detectedNames {
  if (keyboard = "Keychron Q3") {
    currentKeyboard := "keychronQ3"
    break
  }
  else if (keyboard = "Glove80") {
    currentKeyboard := "glove"
    break
  }
}

; Write full details to file
keyboards := GetKeyboardInfo()
outputFile := "keyboard_info.txt"
if FileExist(outputFile) {
  FileDelete(outputFile)
}

for keyboard in keyboards {
  content := "Name: " . keyboard.Name . "`n"
    . "Description: " . keyboard.Description . "`n"
    . "Device ID: " . keyboard.DeviceID . "`n"
    . "PNP Device ID: " . keyboard.PNPDeviceID . "`n"
    . "----------------------------------------`n"
  FileAppend(content, outputFile)
}

; =======================================
; STARTUP / SHUTDOWN
; =======================================
LoadWindowIDs()
LoadChromeWindowList()
VerifyWindowIDs()

OnExit((*) => (
  WriteWindowIDs(),
  SaveChromeWindowList()
))

; =======================================
; PERSISTENCE HELPERS
; =======================================
WriteWindowIDs() {
  global Browser1_ID, Browser2_ID, Browser3_ID, SpotifyWindow_ID, ConfigFile
  IniWrite(Browser1_ID, ConfigFile, "WindowIDs", "Browser1_ID")
  IniWrite(Browser2_ID, ConfigFile, "WindowIDs", "Browser2_ID")
  IniWrite(Browser3_ID, ConfigFile, "WindowIDs", "Browser3_ID")
  IniWrite(SpotifyWindow_ID, ConfigFile, "WindowIDs", "Spotify")
}

VerifyWindowIDs() {
  global Browser1_ID, Browser2_ID, Browser3_ID, SpotifyWindow_ID
  windowsLost := []
  idMap := Map()

  ; First check for invalid windows and build an ID map
  windowVars := [&Browser1_ID, &Browser2_ID, &Browser3_ID, &SpotifyWindow_ID]
  varNames := ["Browser1_ID", "Browser2_ID", "Browser3_ID", "SpotifyWindow_ID"]

  for i, v in windowVars {
    if (%v%) {
      if (!WinExist("ahk_id " . %v%)) {
        %v% := 0
        windowsLost.Push(varNames[i] . " (lost)")
      } else {
        ; Track which variables point to which window IDs
        if (!idMap.Has(%v%)) {
          idMap[%v%] := [i]
        } else {
          idMap[%v%].Push(i)
        }
      }
    }
  }

  ; Handle duplicates - keep only the first variable with each ID
  for id, indexList in idMap {
    if (indexList.Length > 1) {
      ; Keep the first variable, reset the rest
      Loop indexList.Length - 1 {
        dupIndex := indexList[A_Index + 1]
        varName := varNames[dupIndex]

        ; Reset the duplicate using the actual variable name
        if (varName = "Browser1_ID")
          Browser1_ID := 0
        else if (varName = "Browser2_ID")
          Browser2_ID := 0
        else if (varName = "Browser3_ID")
          Browser3_ID := 0
        else if (varName = "SpotifyWindow_ID")
          SpotifyWindow_ID := 0

        windowsLost.Push(varName . " (duplicate)")
      }
    }
  }

  if (windowsLost.Length) {
    lostList := ""
    for idx, name in windowsLost {
      lostList .= (idx > 1 ? ", " : "") . name
    }
    ; MsgBox("Lost/duplicate window(s): " . lostList) ; Uncomment for debugging
  }

  WriteWindowIDs()
}

LoadWindowIDs() {
  global Browser1_ID, Browser2_ID, Browser3_ID, SpotifyWindow_ID, ConfigFile
  ; Default to 0 if not found
  Browser1_ID := IniRead(ConfigFile, "WindowIDs", "Browser1_ID", 0)
  Browser2_ID := IniRead(ConfigFile, "WindowIDs", "Browser2_ID", 0)
  Browser3_ID := IniRead(ConfigFile, "WindowIDs", "Browser3_ID", 0)
  SpotifyWindow_ID := IniRead(ConfigFile, "WindowIDs", "Spotify", 0)
}

SaveChromeWindowList() {
  global ChromeWindowList, ChromeWindowsFile
  ; wipe existing section
  IniDelete(ChromeWindowsFile, "ChromeWindows")
  ids := ""
  for _, id in ChromeWindowList
    ids .= id . ","
  if ids
    ids := SubStr(ids, 1, StrLen(ids) - 1)
  IniWrite(ids, ChromeWindowsFile, "ChromeWindows", "IDs")
}

LoadChromeWindowList() {
  global ChromeWindowList, ChromeWindowsFile
  ChromeWindowList := []
  if !FileExist(ChromeWindowsFile)
    return

  ids := IniRead(ChromeWindowsFile, "ChromeWindows", "IDs", "")
  if ids {
    Loop Parse, ids, ","
      ChromeWindowList.Push(A_LoopField + 0)
  }
}

AddToChromeWindowList(winID) {
  global ChromeWindowList
  for _, id in ChromeWindowList
    if (id = winID)
      return             ; already tracked
  ChromeWindowList.Push(winID)
  SaveChromeWindowList()
}

ResetChromeWindowList() {
  global ChromeWindowList
  for idx, id in ChromeWindowList {
    if (WinExist("ahk_id " id))
      WinClose("ahk_id " id)
  }
  ChromeWindowList := []
  SaveChromeWindowList()
}

; Capture Current Chrome Window
CaptureCurrentChromeWindow(slot) {
  global Browser1_ID, Browser2_ID, Browser3_ID

  ; Get the currently active window
  activeID := WinGetID("A")

  ; Check if it's a Chrome window
  try {
    activeExe := WinGetProcessName("ahk_id " activeID)
    if (activeExe != "chrome.exe") {
      MsgBox("❌ Active window is not Chrome (" activeExe ")")
      return false
    }
  } catch {
    MsgBox("❌ Could not identify active window")
    return false
  }

  ; Assign to the requested slot
  if (slot = 1) {
    Browser1_ID := activeID
    slotName := "Browser1"
  } else if (slot = 2) {
    Browser2_ID := activeID
    slotName := "Browser2"
  } else if (slot = 3) {
    Browser3_ID := activeID
    slotName := "Browser3"
  } else {
    MsgBox("❌ Invalid slot: " slot)
    return false
  }

  ; Add to Chrome window list if not already there
  AddToChromeWindowList(activeID)

  ; Save the changes
  WriteWindowIDs()

  ; Show confirmation
  ToolTip("✅ Captured Chrome window to " slotName " (ID: " activeID ")")
  SetTimer(() => ToolTip(), -2000)

  return true
}

; =======================================
; LEADER‑KEY HOTKEY CREATION
; =======================================

MakeCallback(val) {
  return (*) => AppendLeaderKey(val)
}

; Set the context for dynamically created hotkeys
HotIf (*) => LeaderKeyActive

for letter in StrSplit("abcdefghijklmnopqrstuvwxyz") {
  lower := letter
  upper := StrUpper(letter)
  Hotkey lower, MakeCallback(lower)
  Hotkey "^" lower, MakeCallback(lower)
  Hotkey "+" lower, MakeCallback(upper)
}

for n in StrSplit("0123456789") {
  Hotkey n, MakeCallback(n)
}

Hotkey "Space", MakeCallback("Space")
Hotkey "^Space", MakeCallback("Space")

specials := ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "/", "\", "]", "[", ".",
  ","]
for s in specials {
  Hotkey s, MakeCallback(s)
}

Hotkey "Esc", (*) => CancelLeaderKey()
Hotkey "CapsLock", (*) => CancelLeaderKey()

HotIf

; =======================================
; LEADER‑KEY FUNCTIONS ASSIGNMENT
; =======================================

ActivateLeaderKey() {
  global LeaderKeyActive, LeaderKeyBuffer, LeaderKeyTimeout
  LeaderKeyActive := true
  LeaderKeyBuffer := ""
  SetTimer(CancelLeaderKey, 0) ; reset existing
  SetTimer(CancelLeaderKey, LeaderKeyTimeout)
  ToolTip("Leader mode active")
  SoundPlay("C:\\Windows\\Media\\Windows Balloon.wav")
}


AppendLeaderKey(key) {
  global LeaderKeyBuffer, LeaderCommands
  LeaderKeyBuffer .= key

  ; Check if we have a matching command
  if (LeaderCommands.Has(LeaderKeyBuffer)) {
    LeaderCommands[LeaderKeyBuffer]()
    CancelLeaderKey()
  } else {
    ; Show progress and wait for more keys
    ToolTip("Leader mode: " LeaderKeyBuffer)
  }
}

CancelLeaderKey() {
  global LeaderKeyActive, LeaderKeyBuffer
  LeaderKeyActive := false
  LeaderKeyBuffer := ""
  SetTimer(CancelLeaderKey, 0)
  ToolTip()
}

; =======================================
; WINDOW HELPERS
; =======================================
ActivateOrCreateWindow(&windowID, runCommand, exeName, urls := "") {
  if (IsSet(windowID) && windowID) {
    VerifyWindowIDs()
    if WinExist("ahk_id " windowID) {
      WinActivate("ahk_id " windowID)
      return true
    }
  }

  if (urls)
    runCommand := runCommand " --new-window " urls

  beforeHWNDs := WinGetList("List", "ahk_exe " exeName)
  Run(runCommand)

  newHWND := 0
  Loop 50 {
    Sleep 100
    afterHWNDs := WinGetList("ahk_exe " . exeName)
    for _, hwnd in afterHWNDs {
      found := false
      for _, old in beforeHWNDs {
        if hwnd = old {
          found := true
          break
        }
      }
      if !found {
        newHWND := hwnd
        break 2
      }
    }
  }

  if !newHWND {
    MsgBox "❌ Could not detect the new Chrome window."
    return false
  }

  windowID := newHWND
  WinActivate("ahk_id " newHWND)
  if (exeName = "chrome.exe") {
    AddToChromeWindowList(windowID)
  }
  VerifyWindowIDs()
  return true
}

; ---------- SPECIFIC LAUNCHERS ----------
ActivatePyCharm() {
  SetTitleMatchMode 2
  if WinExist("ahk_exe pycharm64.exe")
    WinActivate
  else {
    ; Try to find PyCharm with wildcard for version
    Loop Files, "C:\Program Files\JetBrains\PyCharm Community Edition*", "D"
    {
      batPath := A_LoopFileFullPath "\bin\pycharm64.exe"
      if FileExist(batPath) {
        Run batPath
        return
      }
    }
    MsgBox "Could not find PyCharm executable."
  }
}

ActivateOBS() {
  if WinExist("ahk_exe obs64.exe")
    WinActivate
  else
    Run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OBS Studio\OBS Studio (64bit).lnk"
}

ActivateDiscord() {
  if WinExist("ahk_exe Discord.exe")
    WinActivate
  else
    Run "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Discord Inc\Discord.lnk"
}

ActivateStreamDeck() {
  if WinExist("ahk_exe StreamDeck.exe")
    WinActivate
  else
    Run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Elgato\Stream Deck\Stream Deck.lnk"
}

ActivateStreamerBot() {
  if WinExist("ahk_exe Streamer.bot.exe")
    WinActivate
  else
    Run "C:\Users\ville\myfiles\programs\Streamer.bot\Streamer.bot.exe"
}

ActivateMailClient() {
  if WinExist("ahk_exe olk.exe")
    WinActivate
  else
    Run "C:\Users\ville\OneDrive\Desktop\Useful\ahk\Outlook - Shortcut.lnk"
}

ActivateSteam() {
  if WinExist("ahk_exe steamwebhelper.exe")
    WinActivate
  else
    Run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Steam\Steam.lnk"
}


ActivateAlacritty() {
  SetTitleMatchMode 2
  if WinExist("ahk_exe alacritty.exe")
    WinActivate
  else
    Run "C:\Users\ville\scoop\apps\alacritty\current\alacritty.exe"
}

ActivateBraveBrowser() {
  if WinExist("ahk_exe brave.exe")
    WinActivate
  else
    Run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Brave.lnk"
}

ActivateSpotify() {
  if WinExist("ahk_exe Spotify.exe")
    WinActivate
  else
    Run "spotify.exe" ; It's some bullshit windows store unfindable path
}

ActivateBrowser1Window() {
  global Browser1_ID
  return ActivateOrCreateWindow(&Browser1_ID,
    "chrome.exe",
    "chrome.exe",
    ; "https://claude.ai https://chat.openai.com"
  )
}

ActivateBrowser2Window() {
  global Browser2_ID
  return ActivateOrCreateWindow(&Browser2_ID,
    "chrome.exe",
    "chrome.exe",
    ; "https://claude.ai https://chat.openai.com"
  )
}

ActivateBrowser3Window() {
  global Browser3_ID
  return ActivateOrCreateWindow(&Browser3_ID,
    "chrome.exe",
    "chrome.exe",
    ; "https://claude.ai https://chat.openai.com"
  )
}

ActivateVSCode() {
  if WinExist("ahk_exe Code.exe")
    WinActivate
  else
    Run "C:\\Users\\" A_UserName "\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe"
}

ActivateWezTerm() {
  primaryPath :=
    "C:\\Users\\ville\\scoop\\apps\\wezterm-nightly\\current\\wezterm-gui.exe"
  fallbackPath := "C:\\Users\\ville\\scoop\\shims\\wezterm-gui.exe"

  if WinExist("ahk_exe wezterm-gui.exe")
    WinActivate
  else if FileExist(primaryPath)
    Run primaryPath
  else if FileExist(fallbackPath)
    Run fallbackPath
  else
    MsgBox "Could not find WezTerm executable at either path:`n" primaryPath "`n" fallbackPath
}

ActivatePowerShell() {
  SetTitleMatchMode 2
  if WinExist("ahk_exe WindowsTerminal.exe")
    WinActivate
  else
    Run "pwsh"
}

ActivateAdminPowerShell() {
  adminTitle := "Administrator: C:\\Program Files\\PowerShell\\7\\pwsh.exe"
  selectAdminTitle := "Select " adminTitle

  if WinExist(adminTitle)
    WinActivate adminTitle
  else if WinExist(selectAdminTitle)
    WinActivate selectAdminTitle
  else
    Run "*RunAs pwsh.exe"
}

ActivateExplorer() {
  if WinExist("ahk_exe explorer.exe ahk_class CabinetWClass")
    WinActivate
  else
    Run "explorer.exe"
}

ActivateNeo4j() {
  SetTitleMatchMode 2
  if WinExist("neo4j@bolt://localhost:7687")
    WinActivate
  else
    Run "C:\\Users\\ville\\AppData\\Local\\Programs\\Neo4j Desktop\\Neo4j Desktop.exe"
}

ActivateKovaaks() {
  if WinExist("ahk_exe FPSAimTrainer-Win64-Shipping.exe")
    WinActivate
  else Run "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Steam\KovaaK 2.0.url"
}

ActivateDeadlock() {
  if WinExist("ahk_exe deadlock.exe")
    WinActivate
  else
    Run "C:\Users\ville\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Steam\Deadlock.url"
}

LaunchDeadLockMovementScript() {
  scriptPath :=
    "C:\Users\ville\myfiles\deadlock-movement-tracker\deadlock-movement-tracker.ahk"
  Run scriptPath
}

WriteMessageDontResendAllCode() {
  SendText "No need to resend me all the code for this one"
}

WriteMessageWorstUserName() {
  SendText "woertsposzibllen4me"
}

ReplaceSlashes(direction := "/") {
  originalClip := ClipboardAll()
  ClipWait(1)
  currentText := A_Clipboard
  if (direction = "/") {
    newText := StrReplace(currentText, "\", "/")
    A_Clipboard := newText
  }
  else if (direction = "\") {
    newText := StrReplace(currentText, "/", "\")
    A_Clipboard := newText
  }
}

; =======================================
; GENERAL HOTKEYS
; =======================================

#HotIf WinActive("ahk_exe wezterm-gui.exe")
^;::F13
^,::+F13
#HotIf

#HotIf WinActive("ahk_exe deadlock.exe")
!+^F12:: LaunchDeadLockMovementScript()
#HotIf

Excludegames() {
  return !WinActive("ahk_exe dota2.exe") && !WinActive("ahk_exe Warcraft III.exe") && !
    WinActive("ahk_exe deadlock.exe")
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

; Mouse pos indicator

overlayGui := ""
isShowing := false

!home:: {
  global isShowing
  if (isShowing) {
    HideOverlay()
  } else {
    ShowOverlay()
  }
}

ShowOverlay() {
  global overlayGui, isShowing

  ; Create a GUI window
  overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
  overlayGui.BackColor := "Black"
  overlayGui.SetFont("s12 cLime", "Consolas")
  overlayGui.Add("Text", "vPosText w200 h30 Center", "X: 0000 Y: 0000")
  overlayGui.Show("x10 y10 NoActivate")

  isShowing := true

  ; Update position every 50ms
  SetTimer(UpdatePosition, 50)
}

HideOverlay() {
  global overlayGui, isShowing

  SetTimer(UpdatePosition, 0)  ; Stop the timer
  if (overlayGui)
    overlayGui.Destroy()

  isShowing := false
}

UpdatePosition() {
  global overlayGui

  MouseGetPos(&xPos, &yPos)
  overlayGui["PosText"].Text := "X: " . xPos . " Y: " . yPos
}
