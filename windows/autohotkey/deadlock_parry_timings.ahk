#Requires AutoHotkey v2.0

class AttemptLog {
  static _buf := []
  static _max := 200
  static _gap_ms := 400.0

  static _qpc_freq := 0
  static _last_qpc := 0

  ; file logging
  static _file_path := ""
  static _file_enabled := false
  static _file_flush_every := 1
  static _file_counter := 0

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

  ; Enable appending log lines to a file.
  ; flush_every: write every N lines (1 = every line)
  static EnableFile(path, flush_every := 1) {
    this._file_path := path
    this._file_enabled := true
    this._file_flush_every := Max(1, Integer(flush_every))
    this._file_counter := 0

    ; ensure directory exists
    SplitPath path, , &dir
    if (dir != "" && !DirExist(dir))
      DirCreate(dir)

    ; header (optional)
    FileAppend("---- AttemptLog started " FormatTime(, "yyyy-MM-dd HH:mm:ss") " ----`n"
      , this._file_path, "UTF-8")
  }

  static DisableFile() {
    this._file_enabled := false
    this._file_path := ""
    this._file_counter := 0
  }

  static Clear() {
    this._buf := []
    this._last_qpc := 0
    ; keep file settings as-is (don’t disable file logging)
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
      line := Format("[{} +{:07.3f}ms] {}", stamp, gap_ms, msg)
    }

    this._buf.Push(line)
    this._last_qpc := now
    this._trim()

    this._maybe_write_file(line, is_new_attempt)
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

  static _maybe_write_file(line, is_new_attempt) {
    if (!this._file_enabled || this._file_path = "")
      return

    this._file_counter += 1

    ; preserve separators in file too
    if (is_new_attempt)
      FileAppend("`n", this._file_path, "UTF-8")

    ; write line (optionally batched)
    ; If flush_every > 1, we still append each time (Windows buffers anyway),
    ; but you can choose to only append every N by buffering yourself.
    ; Keeping it simple and robust here.
    FileAppend(line "`n", this._file_path, "UTF-8")
  }

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


; ---- testing ------------

global LAST_WHEEL_QPC := 0
global WHEEL_BURST_MS := 120  ; treat events within timeframe as 1 burst

WheelHandler(direction) {
  global LAST_WHEEL_QPC, WHEEL_BURST_MS

  now := AttemptLog._qpc_now()
  if (LAST_WHEEL_QPC) {
    delta := (now - LAST_WHEEL_QPC) * 1000.0 / AttemptLog._qpc_freq
    if (delta < WHEEL_BURST_MS)
      return
  }

  LAST_WHEEL_QPC := now
  AttemptLog.Add("Pressed Wheel" direction)
}

~f:: AttemptLog.Add("Pressed f")

~RButton:: AttemptLog.Add("Pressed RButton")
~XButton1:: AttemptLog.Add("Pressed XButton1")
~WheelDown:: WheelHandler("Down")

F12:: AttemptLog.Show()
