#Include ..\ui\delayed-tooltip.ahk
A_MenuMaskKey := "vkFF"

LaunchDeadLockMovementScript() {
  scriptPath :=
    "C:\Users\ville\myfiles\git-repos\deadlock-movement-tracker\deadlock-movement-tracker.ahk"
  Run scriptPath
}

WriteMessageDontResendAllCode() {
  SendText "only resend me the relevant code for this message"
}

ReplaceClipboardSlashes(direction := "/") {
  originalClip := ClipboardAll()
  ClipWait(1)
  currentText := A_Clipboard
  if (direction = "/") {
    newText := StrReplace(currentText, "\", "/")
    A_Clipboard := newText
  }
  else if (direction = "\") {
    newText := StrReplace(currentText, "/", "\")
    A_Clipboard := newText
  }
  DelayedToolTipMsg("Clipboard slashes replaced with " . direction, 1000)
}

SmallPageScrollMove(direction, notches := 4) {
  MouseGetPos(&mx, &my)
  WinGetPos(&x, &y, &w, &h, "A")

  if (mx < x || mx >= x + w || my < y || my >= y + h)
    MouseMove(x + w * 4 // 5, y + h * 4 // 5, 0)

  Send(direction > 0 ? "{WheelUp " notches "}" : "{WheelDown " notches "}")
}
