#Include ..\core\persistence.ahk
#Include ..\streaming-ahk\window-helpers.ahk

ActivateOrCreateWindow(&windowID, runCommand, exeName, urls := "", profile := "",
  winClass := "", activate := true, mousePercent := 100) {
  global Browser1_ID, Browser2_ID, Browser3_ID

  if (IsSet(windowID) && windowID) {
    VerifyWindowIDs()
    if WinExist("ahk_id " windowID) {
      if activate {
        WinActivate("ahk_id " windowID)
        MoveMouseToWindowBottom(windowID, mousePercent)
      }
      return true
    }
  }

  ; IDs already claimed by other slots — never valid candidates for a "new" window
  claimedIDs := [Browser1_ID, Browser2_ID, Browser3_ID]

  if (profile)
    ; for chrome see chrome://version
    runCommand .= ' --profile-directory="' profile '"'

  if (urls)
    runCommand := runCommand " --new-window " urls

  matchCriteria := "ahk_exe " exeName (winClass ? " ahk_class " winClass : "")
  beforeHWNDs := WinGetList(matchCriteria)
  Run(runCommand)

  newHWND := 0
  Loop 50 {
    Sleep 100
    afterHWNDs := WinGetList(matchCriteria)
    for _, hwnd in afterHWNDs {
      if hwnd = windowID
        continue
      found := false
      for _, old in beforeHWNDs {
        if hwnd = old {
          found := true
          break
        }
      }
      if found
        continue
      isClaimed := false
      for _, claimed in claimedIDs {
        if hwnd = claimed {
          isClaimed := true
          break
        }
      }
      if isClaimed
        continue

      ; debounce: make sure it's still alive 150ms later (filters transient popups)
      candidate := hwnd
      Sleep 150
      if WinExist("ahk_id " candidate) {
        newHWND := candidate
        break 2
      }
    }
  }

  if !newHWND {
    MsgBox "❌ Could not detect the new " exeName " window."
    return false
  }

  windowID := newHWND
  if activate
    WinActivate("ahk_id " newHWND)
  if (exeName = "chrome.exe")
    AddToChromeWindowList(windowID)
  VerifyWindowIDs()
  if activate
    MoveMouseToWindowBottom(windowID, mousePercent)
  return true
}
