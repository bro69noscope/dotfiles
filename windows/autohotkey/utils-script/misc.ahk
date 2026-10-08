#Include delayed-tooltip.ahk

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
