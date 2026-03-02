#Requires AutoHotkey v2.0
; attempt_log.ahk — importable logging module (no hotkeys defined)

class AttemptLog {
  static _buf := []
  static _max := 200
  static _gap_ms := 400.0

  static _qpc_freq := 0
  static _last_qpc := 0

  ; -------- public API --------

  static SetMax(n) {
    n := Integer(n)
    if (n < 1)
      n := 1
    this._max := n
    this._trim()
  }

  static SetGap(ms) {
    this._gap_ms := ms + 0.0
    if (this._gap_ms < 0)
      this._gap_ms := 0.0
  }

  static Clear() {
    this._buf := []
    this._last_qpc := 0
  }

  static Add(msg) {
    this._ensure_qpc()

    now := this._qpc_now()
    gap_ms := 0.0
    is_new_attempt := false

    if (this._last_qpc) {
      gap_ms := (now - this._last_qpc) * 1000.0 / this._qpc_freq
      if (gap_ms > this._gap_ms) {
        this._buf.Push("") ; separator line
        is_new_attempt := true
      }
    } else {
      is_new_attempt := true
    }

    stamp := FormatTime(, "HH:mm:ss")

    if (is_new_attempt) {
      line := Format("[{}] {}", stamp, msg)
    } else {
      ; 7 wide incl decimals, 3 decimals => e.g.  15.482ms or   0.732ms
      line := Format("[{} +{:07.3f}ms] {}", stamp, gap_ms, msg)
    }

    this._buf.Push(line)
    this._last_qpc := now
    this._trim()
  }

  static Text() {
    if (this._buf.Length = 0)
      return ""
    out := ""
    for line in this._buf
      out .= line "`n"
    return out
  }

  static Show(title := "Attempt Log") {
    t := this.Text()
    MsgBox(t != "" ? t : "Log is empty", title)
  }

  ; -------- internals --------

  static _trim() {
    while (this._buf.Length > this._max)
      this._buf.RemoveAt(1)
  }

  static _ensure_qpc() {
    if (this._qpc_freq)
      return

    freq := Buffer(8, 0)
    if !DllCall("QueryPerformanceFrequency", "ptr", freq.Ptr)
      throw Error("QueryPerformanceFrequency failed")

    this._qpc_freq := NumGet(freq, 0, "int64")
    if (this._qpc_freq <= 0)
      throw Error("Invalid QPC frequency")
  }

  static _qpc_now() {
    c := Buffer(8, 0)
    DllCall("QueryPerformanceCounter", "ptr", c.Ptr)
    return NumGet(c, 0, "int64")
  }
}
