MoveWindowToAdjacentMonitor(hwnd, direction, wrap := false) {
  DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")

  if !hwnd || !WinExist("ahk_id " hwnd)
    return false

  state := WinGetMinMax("ahk_id " hwnd)
  if (state = -1)
    return false

  ; work areas sorted left to right
  mons := []
  Loop MonitorGetCount() {
    MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
    mons.Push({ l: l, t: t, r: r, b: b })
  }
  Loop mons.Length - 1 {
    i := A_Index + 1
    m := mons[i]
    j := i - 1
    while (j >= 1 && mons[j].l > m.l) {
      mons[j + 1] := mons[j]
      j--
    }
    mons[j + 1] := m
  }

  ; current monitor = one containing window center
  WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
  cx := x + w // 2
  cy := y + h // 2
  cur := 1
  for i, m in mons {
    if (cx >= m.l && cx < m.r && cy >= m.t && cy < m.b) {
      cur := i
      break
    }
  }

  step := (direction = "right") ? 1 : -1
  tgt := cur + step
  if (tgt < 1 || tgt > mons.Length) {
    if !wrap
      return false
    tgt := (step = 1) ? 1 : mons.Length
  }
  if (tgt = cur)
    return false

  wasMax := (state = 1)
  if wasMax
    WinRestore("ahk_id " hwnd)

  ; restored rect, scaled to target work area
  WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
  src := mons[cur]
  dst := mons[tgt]
  sw := src.r - src.l
  sh := src.b - src.t
  dw := dst.r - dst.l
  dh := dst.b - dst.t

  nw := Min(Round(w * dw / sw), dw)
  nh := Min(Round(h * dh / sh), dh)
  nx := dst.l + Round((x - src.l) * dw / sw)
  ny := dst.t + Round((y - src.t) * dh / sh)

  ; keep fully inside target so the center lands on the target monitor
  nx := Max(dst.l, Min(nx, dst.r - nw))
  ny := Max(dst.t, Min(ny, dst.b - nh))

  ; pass 1: cross the boundary, Windows rescales the window for the new DPI
  WinMove(nx, ny, , , "ahk_id " hwnd)
  ; pass 2: set final size after the rescale
  WinMove(nx, ny, nw, nh, "ahk_id " hwnd)

  if wasMax
    WinMaximize("ahk_id " hwnd)
  return true
}

MoveActiveWindowLeft() => MoveWindowToAdjacentMonitor(WinExist("A"), "left")
MoveActiveWindowRight() => MoveWindowToAdjacentMonitor(WinExist("A"), "right")
