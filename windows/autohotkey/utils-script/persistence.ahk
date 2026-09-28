; Window IDs (persisted individually)
Browser1_ID := 0
Browser2_ID := 0
Browser3_ID := 0
SpotifyWindow_ID := 0

; Chrome‑tracking (persisted as a list)
ChromeWindowList := []
ChromeWindowsFile := A_ScriptDir "\chrome_windows.ini"

; Config file for single‑value IDs
ConfigFile := A_ScriptDir "\window_ids.ini"

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
