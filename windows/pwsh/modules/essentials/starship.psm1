## Starship prompt
# The starship prompt finds the Invoke-Starship-* hooks by name. They are global, not exported:
# an exported name with two hyphens causes an import warning.
$global:lastDirectory = (Get-Location).Path

function global:Invoke-Starship-TransientFunction {
  $currentDirectory = (Get-Location).Path

  $time = &starship module time
  $char = &starship module character

  if ($global:lastDirectory -ne $currentDirectory) {
    $dir = &starship module directory
    $global:lastDirectory = $currentDirectory
    return "`e[J`n$dir`n$time$char"
  } else {
    return "`e[J$time$char"
  }
}

# Update directory tracking after each command
function global:Invoke-Starship-PostCommand {
  $global:lastDirectory = (Get-Location).Path
}

# OSC compatible prompt
function global:Invoke-Starship-PreCommand {
  # Cursor shape
  if ($global:_LastViMode -eq 'Command') {
    Write-Host -NoNewLine "`e[0 q"
  } else {
    Write-Host -NoNewLine "`e[6 q"
  }
  # OSC
  $prompt = ""
  $current_location = $executionContext.SessionState.Path.CurrentLocation
  if ($current_location.Provider.Name -eq "FileSystem") {
    $ansi_escape = [char]27
    $provider_path = $current_location.ProviderPath -replace "\\", "/"
    $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
  }
  $host.ui.Write($prompt)
  # Prompt positioning
  if ($Host.UI.RawUI.WindowSize.Height -gt 40) {
    Write-Host "`n`n`n`n" -NoNewline
    Write-Host "$([char]27)[4A" -NoNewline
  }
}

function Initialize-Starship {
  Invoke-Expression (&starship init powershell)
  Enable-TransientPrompt
}
