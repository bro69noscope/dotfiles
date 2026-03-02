#SingleInstance Force
A_MaxHotkeysPerInterval := 99999
SettitleMatchMode 1
SendMode "Event"
SetWorkingDir A_ScriptDir
TraySetIcon "icons\deadlock.png"

#HotIf WinActive("ahk_exe deadlock.exe")
CapsLock::-
LWin::0

!j::Up
!k::Down

!+^F10:: {
  MsgBox "Reloaded script"
  Reload
}

jump := "{Space}"
crouch := "{Shift}"

^Space:: {
  Send crouch
  Sleep 1
  Send jump
}

global LOG_BUFFER := []
global MAX_LOG := 100
global LAST_EVENT_TICK := 0
global GAP_THRESHOLD := 400  ; ms between attempts

Log(msg) {
  global LOG_BUFFER, MAX_LOG, LAST_EVENT_TICK, GAP_THRESHOLD

  now := A_TickCount

  ; If enough time passed → new attempt
  if (LAST_EVENT_TICK && (now - LAST_EVENT_TICK > GAP_THRESHOLD))
    LOG_BUFFER.Push("")  ; blank separator line

  LAST_EVENT_TICK := now

  timestamp := FormatTime(, "HH:mm:ss")
  LOG_BUFFER.Push("[" timestamp "] " msg)

  if (LOG_BUFFER.Length > MAX_LOG)
    LOG_BUFFER.RemoveAt(1)
}

~1:: Log("Pressed 1")
~XButton1:: Log("Pressed Mouse Back Button")

F12:: {
  global LOG_BUFFER

  if (LOG_BUFFER.Length = 0) {
    MsgBox "Log is empty"
    return
  }

  text := ""
  for line in LOG_BUFFER
    text .= line "`n"

  MsgBox text
}

#HotIf
