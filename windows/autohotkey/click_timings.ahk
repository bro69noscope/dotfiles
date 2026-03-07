#Requires AutoHotkey v2.0
#SingleInstance Force

DllCall("winmm\timeBeginPeriod", "UInt", 1)

global REACTION_LOG_CSV := A_ScriptDir "\logs\reaction_log.csv"

class AttemptLog {
  static _buf := []
  static _max := 200
  static _gap_ms := 400.0

  static _qpc_freq := 0
  static _last_qpc := 0

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
        this._buf.Push("")
        is_new_attempt := true
      }
    } else {
      is_new_attempt := true
    }

    stamp := FormatTime(, "HH:mm:ss")

    if (is_new_attempt)
      line := Format("[{}] {}", stamp, msg)
    else
      line := Format("[{} +{:07.3f}ms] {}", stamp, gap_ms, msg)

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

class HPTimer {
  static freq := 0

  static Init() {
    if !this.freq {
      DllCall("QueryPerformanceFrequency", "Int64*", &f := 0)
      this.freq := f
    }
  }

  static Now() {
    DllCall("QueryPerformanceCounter", "Int64*", &c := 0)
    return c
  }

  static ToMs(delta) {
    return delta * 1000.0 / this.freq
  }
}

class ReactionTest {
  static running := false
  static active := false
  static cueGui := 0
  static hotkeys := Map()

  static attemptId := 0
  static startQpc := 0

  static firstKind := ""
  static firstName := ""
  static firstQpc := 0

  static secondWindowMs := 500.0
  static maxReactionMs := 1500.0

  static wheelBurstMs := 120.0
  static lastWheelQpcByInput := Map()

  static mouseInputs := [
    ; "RButton",
    ; "MButton",
    "XButton1",
    ; "XButton2",
    ; "WheelUp",
    ; "WheelDown"
  ]

  static keyInputs := [
    "e"
  ]

  static Start() {
    HPTimer.Init()
    AttemptLog.SetGap(400.0)

    SplitPath REACTION_LOG_CSV, , &dir
    if (dir != "" && !DirExist(dir))
      DirCreate(dir)

    if !FileExist(REACTION_LOG_CSV) {
      FileAppend(
        "attempt_id,timestamp"
        . ",first_input_type,first_input_name,reaction_ms"
        . ",second_input_type,second_input_name,follow_ms,second_total_ms"
        . ",completed`n",
        REACTION_LOG_CSV,
        "UTF-8"
      )
    }

    this.InstallInputHotkeys()
    TrayTip("Reaction Logger", "F8 start, F9 stop, Shift+F12 show log, Esc exit", 1)
  }

  static InstallInputHotkeys() {
    for key in this.mouseInputs
      this.InstallOneHotkey("mouse", key)

    for key in this.keyInputs
      this.InstallOneHotkey("key", key)
  }

  static InstallOneHotkey(kind, name) {
    fn := this.MakeHandler(kind, name)
    Hotkey("~*" name, fn, "On")
    this.hotkeys[kind ":" name] := fn
  }

  static MakeHandler(kind, name) {
    return (*) => this.HandleRawInput(kind, name)
  }

  static StartRunning() {
    if this.running
      return

    this.running := true
    this.active := false
    this.ScheduleNextTrial()
  }

  static StopRunning() {
    this.running := false
    this.EndAttemptTimers()
    this.active := false

    try this.cueGui.Destroy()
    this.cueGui := 0
  }

  static ScheduleNextTrial() {
    if !this.running
      return

    delay := Random(1500, 2500)
    SetTimer(this.BeginTrial.Bind(this), -delay)
  }

  static BeginTrial() {
    if !this.running || this.active
      return

    this.EndAttemptTimers()

    this.attemptId += 1
    this.startQpc := HPTimer.Now()

    this.firstKind := ""
    this.firstName := ""
    this.firstQpc := 0

    this.active := true
    this.ShowCue()

    ; timeout if no first input happens
    SetTimer(this.OnFirstTimeout.Bind(this), -Round(this.maxReactionMs))
  }

  static ShowCue() {
    try this.cueGui.Destroy()

    this.cueGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    this.cueGui.BackColor := "Red"
    this.cueGui.Show("x0 y0 w400 h250 NoActivate")
  }

  static HandleRawInput(kind, name) {
    if !this.active
      return

    if (kind = "mouse" && InStr(name, "Wheel")) {
      if this.IsWheelBurst(name)
        return
    }

    now := HPTimer.Now()

    ; first input
    if !this.firstQpc {
      this.firstKind := kind
      this.firstName := name
      this.firstQpc := now

      reactionMs := HPTimer.ToMs(this.firstQpc - this.startQpc)

      AttemptLog.Add(
        Format(
          "Attempt {} first: {} {} | reaction {:.3f} ms",
          this.attemptId,
          kind,
          name,
          reactionMs
        )
      )

      ToolTip("1st: " name " | " Round(reactionMs, 3) " ms")
      SetTimer(() => ToolTip(), -500)

      ; now wait for second input
      SetTimer(this.OnSecondTimeout.Bind(this), -Round(this.secondWindowMs))
      return
    }

    ; ignore exact same wheel burst or accidental duplicate super-fast press
    if (kind = this.firstKind && name = this.firstName) {
      deltaSameMs := HPTimer.ToMs(now - this.firstQpc)
      if (deltaSameMs < 30.0)
        return
    }

    this.FinishWithSecond(kind, name, now)
  }

  static FinishWithSecond(kind, name, secondQpc) {
    if !this.active || !this.firstQpc
      return

    reactionMs := HPTimer.ToMs(this.firstQpc - this.startQpc)
    followMs := HPTimer.ToMs(secondQpc - this.firstQpc)
    secondTotalMs := HPTimer.ToMs(secondQpc - this.startQpc)

    this.WriteCsv(
      this.attemptId,
      this.firstKind,
      this.firstName,
      reactionMs,
      kind,
      name,
      followMs,
      secondTotalMs,
      1
    )

    AttemptLog.Add(
      Format(
        "Attempt {} second: {} {} | follow {:.3f} ms | total {:.3f} ms",
        this.attemptId,
        kind,
        name,
        followMs,
        secondTotalMs
      )
    )

    ToolTip(
      "1st: " this.firstName " " Round(reactionMs, 1) " ms"
      . " | 2nd: " name " +" Round(followMs, 1) " ms"
    )
    SetTimer(() => ToolTip(), -900)

    this.EndCurrentAttempt()
    this.ScheduleNextTrial()
  }

  static OnFirstTimeout() {
    if !this.active || this.firstQpc
      return

    AttemptLog.Add("Attempt " this.attemptId " timed out: no first input")
    this.EndCurrentAttempt()
    this.ScheduleNextTrial()
  }

  static OnSecondTimeout() {
    if !this.active || !this.firstQpc
      return

    reactionMs := HPTimer.ToMs(this.firstQpc - this.startQpc)

    this.WriteCsv(
      this.attemptId,
      this.firstKind,
      this.firstName,
      reactionMs,
      "",
      "",
      "",
      "",
      0
    )

    AttemptLog.Add(
      Format(
        "Attempt {} second timeout | first {} {} | reaction {:.3f} ms",
        this.attemptId,
        this.firstKind,
        this.firstName,
        reactionMs
      )
    )

    ToolTip("1st: " this.firstName " | no 2nd input")
    SetTimer(() => ToolTip(), -800)

    this.EndCurrentAttempt()
    this.ScheduleNextTrial()
  }

  static EndCurrentAttempt() {
    this.EndAttemptTimers()
    this.active := false

    try this.cueGui.Destroy()
    this.cueGui := 0

    this.firstKind := ""
    this.firstName := ""
    this.firstQpc := 0
  }

  static EndAttemptTimers() {
    SetTimer(this.BeginTrial.Bind(this), 0)
    SetTimer(this.OnFirstTimeout.Bind(this), 0)
    SetTimer(this.OnSecondTimeout.Bind(this), 0)
  }

  static IsWheelBurst(name) {
    now := HPTimer.Now()

    if this.lastWheelQpcByInput.Has(name) {
      prev := this.lastWheelQpcByInput[name]
      delta := HPTimer.ToMs(now - prev)
      if (delta < this.wheelBurstMs)
        return true
    }

    this.lastWheelQpcByInput[name] := now
    return false
  }

  static CsvField(v) {
    s := String(v)
    q := Chr(34)

    if InStr(s, ",") || InStr(s, q)
      return q StrReplace(s, q, q q) q

    return s
  }

  static WriteCsv(
    attemptId,
    firstType,
    firstName,
    reactionMs,
    secondType,
    secondName,
    followMs,
    secondTotalMs,
    completed
  ) {
    ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

    line :=
      this.CsvField(attemptId) ","
      . this.CsvField(ts) ","
      . this.CsvField(firstType) ","
      . this.CsvField(firstName) ","
      . this.CsvField(reactionMs = "" ? "" : Format("{:.3f}", reactionMs)) ","
      . this.CsvField(secondType) ","
      . this.CsvField(secondName) ","
      . this.CsvField(followMs = "" ? "" : Format("{:.3f}", followMs)) ","
      . this.CsvField(secondTotalMs = "" ? "" : Format("{:.3f}", secondTotalMs)) ","
      . this.CsvField(completed)
      . "`n"

    FileAppend(line, REACTION_LOG_CSV, "UTF-8")
  }
}

ReactionTest.Start()

F11:: ReactionTest.StartRunning()
F12:: ReactionTest.StopRunning()
Esc:: ExitApp
