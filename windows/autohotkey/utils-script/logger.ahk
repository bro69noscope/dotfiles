LogError(msg, logFile) {
  ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
  try FileAppend(ts " " msg "`n", logFile)
}

TrimLogFile(path, maxBytes) {
  if !FileExist(path) || FileGetSize(path) <= maxBytes
    return

  content := FileRead(path)
  half := StrLen(content) // 2
  cut := InStr(content, "`n", , half)
  trimmed := cut ? SubStr(content, cut + 1) : SubStr(content, half)

  FileDelete(path)
  FileAppend(trimmed, path)
}
