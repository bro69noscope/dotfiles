#Include app-launchers.ahk
#Include delayed-tooltip.ahk
#Include logger.ahk
#Include config.ahk

GroupedAppsLogFile := "logs\grouped-apps-manager.log"
TrimLogFile(GroupedAppsLogFile, 200000)
LogBlank(GroupedAppsLogFile)

SbProduction := Map(
  "find", (*) => FindWindowByExeAndTitle(StreamerbotExe, "production"),
  "start", (*) => ActivateStreamerBot(portableVersion := "production")
)

SbFtp := Map(
  "find", (*) => FindWindowByExeAndTitle(StreamerbotExe, "ftp"),
  "start", (*) => ActivateStreamerBot(portableVersion := "ftp")
)

ObsProd := Map(
  "find", (*) => FindWindowByExeAndTitle(ObsExe, "", "Portable Mode"),
  "start", (*) => ActivateObsProduction()
)

ObsFtp := Map(
  "find", (*) => FindWindowByExeAndTitle(ObsExe, FtpPortableString),
  "start", (*) => ActivateOBSPortable(profile := "ftp")
)

ObsVcam := Map(
  "find", (*) => FindWindowByExeAndTitle(ObsExe, VcamPortableString),
  "start", (*) => ActivateOBSPortable(profile := "vcam")
)

StreamAppGroups := Map(
  "production", [SbProduction, ObsProd],
  "ftp", [SbFtp, ObsFtp, ObsVcam],
  "obs", [ObsProd, ObsFtp, ObsVcam],
  "sbot", [SbProduction, SbFtp],
  "all", [SbProduction, ObsProd, SbFtp, ObsFtp, ObsVcam]
)

QuitStreamDeckScript := StreamingRepoPath .
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

GetStreamApps(group) {
  if group = "all" {
    apps := StreamAppGroups["production"].Clone()
    apps.Push(StreamAppGroups["ftp"]*)
    return apps
  }
  return StreamAppGroups[group].Clone()
}

CloseStreamApps(group := "production") {
  apps := GetStreamApps(group)

  if group == "all"
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
      msg := "WinClose failed: '" title "' hwnd " hwnd ": " e.Message
      LogError(msg, GroupedAppsLogFile)
      continue
    }
    pending.Push({ hwnd: hwnd, title: title })
  }

  for p in pending {
    if !WinWaitClose(p.hwnd, , 8000 / 1000) {
      msg := "Failed to close: '" p.title "'"
      LogError(msg, GroupedAppsLogFile)
      DelayedToolTipMsg(msg)
    }
  }

  DelayedToolTipMsg("Closed stream apps: " group)
}

StartStreamApps(group := "production") {
  apps := GetStreamApps(group)

  if group == "all"
    ActivateStreamDeck()

  for app in apps
    app["start"]()
  DelayedToolTipMsg("Started stream apps: " group)
}
