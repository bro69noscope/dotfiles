#Include persistence.ahk

EnsureFullscreen(hwnd) {
  if WinGetMinMax(hwnd) != 1
    WinMaximize(hwnd)
}

GetMonitorAt(x, y) {
  loop MonitorGetCount() {
    MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
    if (x >= l && x < r && y >= t && y < b)
      return A_Index
  }
  return MonitorGetPrimary()
}

ActivateWhenReady(checkFn, timeout := 2000, callback := "") {
  end := A_TickCount + timeout
  while (A_TickCount < end) {
    if (hwnd := checkFn()) {
      WinActivate(hwnd)
      if callback
        callback(hwnd)
      return true
    }
    Sleep 50
  }
  return false
}

ActivateOrRun(idMethod, runCommand, timeout := 3000, onFound := "") {
  hwnd := idMethod()
  if hwnd {
    WinActivate(hwnd)
    if onFound
      onFound(hwnd)
    return true
  }
  Run(runCommand)
  return ActivateWhenReady(idMethod, timeout, onFound)
}

ActivateOrCreateWindow(&windowID, runCommand, exeName, urls := "", profile := "",
  winClass := "") {
  global Browser1_ID, Browser2_ID, Browser3_ID

  if (IsSet(windowID) && windowID) {
    VerifyWindowIDs()
    if WinExist("ahk_id " windowID) {
      WinActivate("ahk_id " windowID)
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
  WinActivate("ahk_id " newHWND)
  if (exeName = "chrome.exe")
    AddToChromeWindowList(windowID)
  VerifyWindowIDs()
  return true
}

; NOTE:
; Alacritty/winit briefly creates a WS_EX_NOACTIVATE helper window during startup  that
; also matches "ahk_exe alacritty.exe". That window can never be activated - it's
; explicitly excluded from focus. Filter it out and only match the real top-level
; window: visible, and not marked no-activate.
FindAlacrittyMainWindow() {
  EX_NOACTIVATE := 0x08000000

  for hwnd in WinGetList("ahk_exe alacritty.exe") {
    exStyle := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr")
    if !(exStyle & EX_NOACTIVATE) && DllCall("IsWindowVisible", "ptr", hwnd, "int")
      return hwnd
  }
  return 0
}
