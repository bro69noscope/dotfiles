#Include ..\core\persistence.ahk
#Include window-helpers.ahk
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

ActivateBrowser1Window() {
  global Browser1_ID
  return ActivateOrCreateWindow(&Browser1_ID, "chrome.exe", "chrome.exe", , "Default",
    "Chrome_WidgetWin_1")
}

ActivateBrowser2Window() {
  global Browser2_ID
  return ActivateOrCreateWindow(&Browser2_ID, "chrome.exe", "chrome.exe", , "Profile 4",
    "Chrome_WidgetWin_1"
  )
}

ActivateBrowser3Window() {
  global Browser3_ID
  return ActivateOrCreateWindow(&Browser3_ID, "chrome.exe", "chrome.exe", , "Profile 5",
    "Chrome_WidgetWin_1"
  )
}

; Find and activate a Chrome window that isn't in the tracked ChromeWindowList
ActivateUngroupedChromeWindow() {
  global ChromeWindowList

  allChromeWindows := WinGetList("ahk_exe chrome.exe")

  for _, hwnd in allChromeWindows {
    tracked := false
    for _, trackedID in ChromeWindowList {
      if (hwnd = trackedID) {
        tracked := true
        break
      }
    }
    if !tracked {
      WinActivate("ahk_id " hwnd)
      return true
    }
  }

  MsgBox("❌ No ungrouped Chrome windows found")
  return false
}
