#SingleInstance Force
A_MaxHotkeysPerInterval := 99999
SettitleMatchMode 1
SendMode "Event"
SetKeyDelay 5
SetWorkingDir A_ScriptDir
TraySetIcon "icons\deadlock.png"

#HotIf WinActive("ahk_exe deadlock.exe")
CapsLock::]
LWin::[

!j::Up
!k::Down


; --- experimentals ---

; #SuspendExempt
; ^!+F9:: {
;   Suspend -1
;   MsgBox A_IsSuspended ? "SUSPENDED" : "RESUMED"
; }
;
; ^!+F10:: {
;   MsgBox "reloaded script..."
;   Reload
; }
; #SuspendExempt False
;
; jump := "{Space}"
; crouch := "{Shift}"
; dash := "{WheelUp}"
; melee := "q"
;
; ^Space:: {
;   Send crouch
;   Sleep 1
;   Send jump
; }

; !LButton::ins
;
; global WD_next_ok := 0
; global WD_cooldown_ms := 200
;
; WheelDown:: {
;   global WD_next_ok, WD_cooldown_ms
;
;   now := A_TickCount
;   if (now < WD_next_ok)
;     return
;
;   WD_next_ok := now + WD_cooldown_ms
;
;   Send jump
;   Sleep 1
;   Send dash
; }

#Include deadlock_parry_timings.ahk
#HotIf
