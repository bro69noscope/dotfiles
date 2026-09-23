#Include app-launchers.ahk
#Include delayed-tooltip.ahk
#Include logger.ahk

global LogFile := "logs\grouped-apps-manager.log"
LogError("`n", LogFile)
TrimLogFile(LogFile, 1024 * 1024)

global StreamAppGroups := Map(
  "production", [
    Map("find", (*) => FindWindowByExeAndTitle("Streamer.bot.exe", "production"),
      "start", (*) => ActivateStreamerBot(portableVersion := "production")),
    Map("find", (*) => FindWindowByExeAndTitle("obs64.exe", "", "Portable Mode"),
      "start", (*) => ActivateOBS()),
  ],
  "ftp", [
    Map("find", (*) => FindWindowByExeAndTitle("Streamer.bot.exe", "ftp"),
      "start", (*) => ActivateStreamerBot(portableVersion := "ftp")),
    Map("find", (*) => FindWindowByExeAndTitle("obs64.exe",
      "Portable Mode - Profile: ftp"),
      "start", (*) => ActivateOBSPortable(profile := "ftp")),
    Map("find", (*) => FindWindowByExeAndTitle("obs64.exe",
      "Portable Mode - Profile: vcam"),
      "start", (*) => ActivateOBSPortable(profile := "vcam")),
  ]
)

global QuitStreamDeckScript := StreamingRepoPath .
  "external\streamdeck\utils\quit-streamdeck\quit-streamdeck.vbs"

FindWindowByExeAndTitle(exeName, include := "", exclude := "") {
  prev := DetectHiddenWindows(true)
  try {
    for hwnd in WinGetList("ahk_exe " exeName) {
      title := WinGetTitle(hwnd)
      if (include && !InStr(title, include))
        continue
      if (exclude && InStr(title, exclude))
        continue
      return hwnd
    }
    return 0
  } finally DetectHiddenWindows(prev)
}

QuitStreamDeck() {
  if FileExist(QuitStreamDeckScript)
    RunWait('wscript.exe "' QuitStreamDeckScript '"')
  else
    MsgBox "quit-streamdeck.vbs not found at:`n" QuitStreamDeckScript
}

CloseStreamApps(group := "production") {
  apps := StreamAppGroups["production"].Clone()
  if group = "all"
    apps.Push(StreamAppGroups["ftp"]*)

  QuitStreamDeck()

  pending := []
  for app in apps {
    hwnd := app["find"]()
    if !hwnd
      continue
    title := WinGetTitle(hwnd)
    try
      WinClose(hwnd)
    catch as e {
      LogError("WinClose failed: '" title "' hwnd " hwnd ": " e.Message, LogFile)
      continue
    }
    pending.Push({ hwnd: hwnd, title: title })
  }

  for p in pending {
    if !WinWaitClose(p.hwnd, , 8000 / 1000) {
      msg := "Failed to close: '" p.title "'"
      LogError(msg, LogFile)
      DelayedToolTipMsg(msg)
    }
  }

  DelayedToolTipMsg("Closed stream apps: " group)
}

StartStreamApps(group := "production") {
  apps := StreamAppGroups["production"].Clone()
  if group = "all"
    apps.Push(StreamAppGroups["ftp"]*)

  ActivateStreamDeck()
  for app in apps
    app["start"]()
  DelayedToolTipMsg("Started stream apps: " group)
}
