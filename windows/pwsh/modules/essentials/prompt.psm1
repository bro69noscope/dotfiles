function Clear-AndPutPromptAtBottom {
  $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
  Clear-Host
  $consoleHeight = $host.UI.RawUI.WindowSize.Height
  Write-Host "$([char]27)[${consoleHeight}B" -NoNewline
}
