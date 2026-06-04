#SingleInstance Force
A_MaxHotkeysPerInterval := 50000
SetTitleMatchMode 3
SetWorkingDir A_ScriptDir
TraySetIcon "icons\aoe2.png"
SendMode "Event"
#HotIf WinActive("ahk_exe AoE2DE_s.exe")

Home:: {
  sleep 100
  Send "{Enter}"
  sleep 100
  Send "rowshep"
  sleep 100
  Send "{Enter}"

  sleep 100
  Send "{Enter}"
  sleep 100
  Send "my cpu can handle it"
  sleep 100
  Send "{Enter}"

  sleep 100
  Send "{Enter}"
  sleep 100
  Send "aegis"
  sleep 100
  Send "{Enter}"

  sleep 100
  Send "{Enter}"
  sleep 100
  Send "marco"
  sleep 100
  Send "{Enter}"

  sleep 100
  Send "{Enter}"
  sleep 100
  Send "polo"
  sleep 100
  Send "{Enter}"
}

+Home:: {
  sleep 100
  Send "{Enter}"
  sleep 100
  Send "aegis"
  sleep 100
  Send "{Enter}"
}

^Home:: {
  sleep 100
  Send "{Enter}"
  sleep 100
  Send "N\A"
  sleep 100
  Send "{Enter}"
}

!Home:: {
  sleep 100
  Send "{Enter}"
  sleep 100
  Send "N\A"
  sleep 100
  Send "{Enter}"
}
