GetNvimConfigPath() {
  path := EnvGet("NVIM_CONFIG_PATH")
  if path = "" {
    path := "C:/Users/ville/myfiles/dotfiles/nvim-config3.0"
    MsgBox("NVIM_CONFIG_PATH env var is not set, falling back to:`n" path,
      "nvim-scratch", "Icon!")
  }
  return StrReplace(path, "\", "/")
}

global nvimConfigPath := GetNvimConfigPath()
global scratchDir := A_Temp "\nvim-scratch"
global loopScript := scratchDir "\loop.ps1"
global reqFile := scratchDir "\request.txt"
global doneFlag := scratchDir "\done.flag"
global pidFile := scratchDir "\shell.pid"
global scratchTitle := "[[NVIM-SCRATCH]]"
global scratchHwnd := 0
global lastActiveHwnd := 0
global nvimRunning := false

DirExist(scratchDir) || DirCreate(scratchDir)
KillStaleScratchShell()
WriteLoopScript()

for f in [reqFile, doneFlag]
  if FileExist(f)
    FileDelete(f)
OnExit((*) => KillStaleScratchShell())

LaunchScratchShell()


ClipAndOpenNvimScratch() {
  if nvimRunning {
    OpenNvimScratch()
    return
  }

  ClipWait(1)
  savedClip := A_Clipboard
  A_Clipboard := ""
  Send("^c")
  if !ClipWait(0.2, 1) {
    A_Clipboard := savedClip
    ToolTip("No text selected to copy to clipboard")

    ; solve some ux issues by exiting nvim pending operator mode that could be triggered
    ; by the ^c copy command. Usually harmless to send, especially since, if no clip
    ; data was populated, we had no selection that could've been lost
    Send("{Esc}")

    SetTimer(() => ToolTip(), -1000)
    return
  }
  OpenNvimScratch()
}

OpenNvimScratch() {
  ; buffer content will be set from clipboard register in nvim autocommand
  global lastActiveHwnd, nvimRunning

  if nvimRunning {
    WinActivate("ahk_id " scratchHwnd)
    return
  }

  lastActiveHwnd := WinExist("A")

  if !(scratchHwnd && WinExist("ahk_id " scratchHwnd)) {
    nvimRunning := false
    if !LaunchScratchShell()
      return
  }

  if FileExist(doneFlag)
    FileDelete(doneFlag)

  file := scratchDir "\scratch_" FormatTime(, "yyyyMMdd_HHmmss") ".md"
  tmp := reqFile ".tmp"
  FileAppend(file, tmp, "UTF-8-RAW")
  FileMove(tmp, reqFile, 1)
  nvimRunning := true

  WinActivate("ahk_id " scratchHwnd)
  SetTimer(CheckDoneFlag, 100)
}

LaunchScratchShell() {
  global scratchHwnd
  before := Map()
  for hwnd in WinGetList("ahk_exe wezterm-gui.exe")
    before[hwnd] := true
  Run('wezterm.exe start -- pwsh -NoProfile -NoLogo -File "' loopScript '"')
  loop 150 {
    Sleep(50)
    for hwnd in WinGetList("ahk_exe wezterm-gui.exe")
      if !before.Has(hwnd) {
        scratchHwnd := hwnd
        return true
      }
  }
  MsgBox("Could not find the nvim scratch wezterm window after launching it")
  return false
}

WriteLoopScript() {
  nl := "`n"
  content := "$esc = [char]27" nl
    . "$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('" scratchTitle "'))" nl
    . '[Console]::Write("$esc]1337;SetUserVar=WEZTERM_TITLE=$b64$esc\")' nl
    . '$PID | Set-Content -NoNewline -Encoding utf8 "' pidFile '"' nl
    . '$cfg = "' nvimConfigPath '"' nl
    . '& nvim --cmd "set rtp^=$cfg" --cmd "let g:nvim_scratch = 1" -u "$cfg/init.lua"' nl

  if FileExist(loopScript)
    FileDelete(loopScript)
  FileAppend(content, loopScript, "UTF-8-RAW")
}

KillStaleScratchShell() {
  if !FileExist(pidFile)
    return
  pid := Integer(RegExReplace(FileRead(pidFile, "UTF-8"), "[^\d]"))
  FileDelete(pidFile)
  if ProcessExist(pid)
    ProcessClose(pid)
}

CheckDoneFlag() {
  global nvimRunning
  DetectHiddenWindows(true)
  if !WinExist("ahk_id " scratchHwnd) {
    SetTimer(CheckDoneFlag, 0)
    nvimRunning := false
    return
  }
  if !FileExist(doneFlag)
    return
  FileDelete(doneFlag)
  SetTimer(CheckDoneFlag, 0)
  nvimRunning := false
  if lastActiveHwnd && WinExist("ahk_id " lastActiveHwnd)
    WinActivate("ahk_id " lastActiveHwnd)
}
