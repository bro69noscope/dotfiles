; Used to be able to display a ToolTip message after the systematc ToolTip clear
; triggered by having a cmd match the leaderkey buffer happens
DelayedToolTipMsg(text, duration := 2000) {
  SetTimer(() => (
    ToolTip(text),
    SetTimer(() => ToolTip(), -duration)
  ), -10)
}
