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

#Include deadlock_parry_timings.ahk
#HotIf
