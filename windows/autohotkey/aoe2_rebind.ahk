#SingleInstance Force
A_MaxHotkeysPerInterval := 50000
SetTitleMatchMode 3
SetWorkingDir A_ScriptDir
TraySetIcon "icons\aoe2.png"
SendMode "Event"
#HotIf WinActive("ahk_exe AoE2DE_s.exe")

Home:: {
  sleep 60
  Send "{Enter}"
  sleep 60
  Send "rowshep"
  sleep 60
  Send "{Enter}"

  sleep 60
  Send "{Enter}"
  sleep 60
  Send "my cpu can handle it"
  sleep 60
  Send "{Enter}"

  sleep 60
  Send "{Enter}"
  sleep 60
  Send "aegis"
  sleep 60
  Send "{Enter}"

  sleep 60
  Send "{Enter}"
  sleep 60
  Send "marco"
  sleep 60
  Send "{Enter}"

  sleep 60
  Send "{Enter}"
  sleep 60
  Send "polo"
  sleep 60
  Send "{Enter}"
}

+Home:: {
  sleep 60
  Send "{Enter}"
  sleep 60
  Send "aegis"
  sleep 60
  Send "{Enter}"
}

^Home:: {
  sleep 60
  Send "{Enter}"
  sleep 60
  Send "N\A"
  sleep 60
  Send "{Enter}"
}

!Home:: {
  sleep 60
  Send "{Enter}"
  sleep 60
  Send "N\A"
  sleep 60
  Send "{Enter}"
}
