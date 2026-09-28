#Include config.ahk
#Include leader-hotkeys.ahk
LeaderKeyActive := false
LeaderKeyBuffer := ""
LeaderKeyTimeout := 2000

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

specials := [
  "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "/", "\", "]", "[", ".", ",", ";",
  "-", "_", "=", "+", "{", "}", "|", ":", "'", "``", "~"
]

for s in specials {
  Hotkey s, MakeCallback(s)
}

Hotkey "Esc", (*) => CancelLeaderKey()
Hotkey "CapsLock", (*) => CancelLeaderKey()

HotIf

ActivateLeaderKey() {
  global LeaderKeyActive, LeaderKeyBuffer, LeaderKeyTimeout
  LeaderKeyActive := true
  LeaderKeyBuffer := ""
  SetTimer(CancelLeaderKey, 0) ; reset existing
  SetTimer(CancelLeaderKey, LeaderKeyTimeout)
  ToolTip("Leader mode active")
  SoundPlay("C:\Windows\Media\Windows Balloon.wav")
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
