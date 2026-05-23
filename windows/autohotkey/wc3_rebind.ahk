#SingleInstance Force
A_MaxHotkeysPerInterval := 50000
SetTitleMatchMode 3
#HotIf WinActive("Warcraft III")
SetWorkingDir A_ScriptDir
TraySetIcon "icons\wc3.png"
SendMode "Event"

; Configure togglable mouse wheel binding for +/- keys for ez replay scrubbing (Toggle off to avoid changing game speed in customs)
global WheelEnabled := false

+Space:: Send "p"

*WheelUp:: {
  if WheelEnabled
    Send "="
  else
    return
}

*WheelDown:: {
  if WheelEnabled
    Send "-"
  else
    return
}

End:: {
  global WheelEnabled := !WheelEnabled
  if WheelEnabled
    ToolTip("Wheel Enabled: Bound to +/- keys", 0, 0)
  else
    ToolTip("Wheel Disabled", 0, 0)
  SetTimer RemoveToolTip, 2000
}

RemoveToolTip() {
  SetTimer RemoveToolTip, 0
  ToolTip
}

; ; Disable some alt combos temporarily
; !q:: return
; !a:: return
; !s:: return
; !d:: return
; !f:: return
; !c:: return
; !v:: return
; ^s:: return
;
; ; Inactive peons/Town hall navigation
; `::F8
; CapsLock::BackSpace
;
; ; Control groups
; XButton1 & a::5
; XButton1 & s::6
; XButton1 & d::7
; XButton1 & f::8
; XButton1 & c::9
; g::0
; XButton2::l
;
;
; ; This whole mess is to fix an issue with keypress displayers when pressing and releasing the mouse button and the letter key in a weird unusual order
; MButton:: {
;   Send "{a up}{s up}{d up}{f up}{c up}"
;   Send "{MButton down}"
; }
;
; MButton up:: {
;   Send "{MButton up}"
; }
;
; a up:: {
;   Send "{5 up}"
;   Send "{a up}"
; }
;
; s up:: {
;   Send "{6 up}"
;   Send "{s up}"
; }
;
; d up:: {
;   Send "{7 up}"
;   Send "{d up}"
; }
;
; f up:: {
;   Send "{8 up}"
;   Send "{f up}"
; }
;
; c up:: {
;   Send "{9 up}"
;   Send "{c up}"
; }
;
; a::a
; s::s
; d::d
; f::f
; c::c

; Custom game quick cheats setup
Home:: {
  Send "{Enter}"
  Send "greedisgood 900000"
  Send "{Enter}"

  Send "{Enter}"
  Send "pointbreak"
  Send "{Enter}"

  Send "{Enter}"
  Send "warpten"
  Send "{Enter}"

  Send "{Enter}"
  Send "synergy"
  Send "{Enter}"

  Send "{Enter}"
  Send "iocainepowder"
  Send "{Enter}"

  Send "{Enter}"
  Send "Thereisnospoon"
  Send "{Enter}"
}

!Home:: {
  Send "{Enter}"
  Send "whosyourdaddy"
  Send "{Enter}"
}

+Home:: {
  Send "{Enter}"
  Send "warpten"
  Send "{Enter}"
}

^Home:: {
  Send "{Enter}"
  Send "thedudeabides"
  Send "{Enter}"

  Send "{Enter}"
  Send "thedudeabides"
  Send "{Enter}"
}

^+Home:: {
  Send "{Enter}"
  Send "daylightsavings"
  Send "{Space}"
}

#HotIf
