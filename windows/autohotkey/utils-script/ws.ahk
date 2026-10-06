#Include libs/websocket.ahk
#Include app-launchers.ahk
#Include logger.ahk

WsLogFile := "logs\ws.log"
TrimLogFile(WsLogFile, 200000)
LogBlank(WsLogFile)

msgboxShown := false
portsEnvVar := "NLLS_PORTS_FILE"


wsCommands := Map(
  "MoveProductionObsRight", () => MoveProductionOBS("right"),
  "MoveProductionObsCenter", () => MoveProductionOBS("center"),
  "ActivateStreamFeedApp", () => ActivateStreamFeedApp(),
  "ActivateObs", () => ActivateOBS(true),
  "ActivateObsPortableFtp", () => ActivateOBSPortable("ftp", true)
)

NoticeError(msg) {
  global msgboxShown
  if !msgboxShown {
    MsgBox(msg, "Error", "Iconx T8")
    msgboxShown := true
  }
  LogError(msg, WsLogFile)
}

GetPortsFile() {
  portsFile := EnvGet(portsEnvVar)
  if !portsFile
    portsFile := RegRead("HKCU\Environment", portsEnvVar, "")
  if !portsFile {
    e := portsEnvVar " env var is not set in env or HKCU\Environment."
    NoticeError(e)
    throw Error(e)
  }
  return portsFile
}


GetRelayPort() {
  portsFile := GetPortsFile()

  if !FileExist(portsFile) {
    e := portsEnvVar " points to a missing file: " portsFile
    NoticeError(e)
    throw Error(e)
  }

  ports := FileRead(portsFile)
  if RegExMatch(ports, 'python\s*:\s*\{[^}]*?\bport\s*:\s*(\d+)', &m)
    return m[1]

  e := "repository.python port not found in " portsFile
  NoticeError(e)
  throw Error(e)
}

ws := ""
Connect()

Connect() {
  global ws
  try
    ws := WebSocket("ws://127.0.0.1:" GetRelayPort() "/ahk/listen", {
      message: OnWsMessage,
      close: (*) => SetTimer(Connect, -2000)
    })
  catch as e {
    LogError("ws connect failed: " e.Message, WsLogFile)
    SetTimer(Connect, -2000)
  }
}

OnWsMessage(this, msg) {
  LogInfo("ws msg: '" msg "'", WsLogFile)
  if wsCommands.Has(msg)
    wsCommands[msg]()
  else
    LogWarn("ws unknown command: '" msg "'", WsLogFile)
}
