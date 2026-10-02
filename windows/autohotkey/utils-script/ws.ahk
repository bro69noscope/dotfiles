#Include libs/websocket.ahk
#Include app-launchers.ahk

wsCommands := Map(
  "MoveProductionObsRight", () => MoveProductionOBS("right"),
  "MoveProductionObsCenter", () => MoveProductionOBS("center"),
  "ActivateStreamFeedApp", () => ActivateStreamFeedApp(),
  "ActivateObs", () => ActivateOBS(true),
  "ActivateObsPortableFtp", () => ActivateOBSPortable("ftp", true)
)

GetRelayPort() {
  config := FileRead(A_ScriptDir "\relay.config.json")
  if RegExMatch(config, '"port"\s*:\s*(\d+)', &m)
    return m[1]
  throw Error("no port in relay.config.json")
}

ws := ""
Connect()

Connect() {
  global ws
  try
    ws := WebSocket("ws://127.0.0.1:" GetRelayPort() "/ahk", {
      message: OnWsMessage,
      close: (*) => SetTimer(Connect, -2000)
    })
  catch
    SetTimer(Connect, -2000)
}

OnWsMessage(this, msg) {
  if wsCommands.Has(msg)
    wsCommands[msg]()
}
