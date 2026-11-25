# Keep prompt at the bottom of the terminal during startup
$consoleHeight = $host.UI.RawUI.WindowSize.Height
Write-Host ("`n" * $consoleHeight)

## Constants
# $claudeApiKey = Get-Content -Path `
#   "$HOME\myfiles\documents\api-keys\anthropic\loïc-onboarding-api-key.txt" -Raw

## Environment variables
# Registry-set vars are documented in windows\env\registry-env-vars.ps1
# $PSScriptRoot is the symlink location here, so the dotfiles path is spelled out.
# Files load in name order: streaming.ps1 needs paths.ps1.
Get-ChildItem "$HOME\myfiles\dotfiles\windows\pwsh\env\vars\*.ps1" |
  Sort-Object Name | ForEach-Object { . $_.FullName }

## Modules
Import-Module Terminal-Icons
Import-Module posh-git

## Custom modules
foreach (
  $module in Get-ChildItem "$env:DOTFILES_PATH\windows\pwsh\modules" -Filter *.psm1 -Recurse) {
  Import-Module $module.FullName -Force
}

# -> Modules external to dotfiles repo:
Import-Module (
  Join-Path `
    $env:BRO_NLLS_REPO_PATH `
    "external\common\streaming-software\version-control\load-stream-modules.psm1"
) -Force

## Imported functions aliases
# general
Set-Alias -Name spp -Value Set-PythonPath
Set-Alias -Name eme -Value Enter-MegaScriptEnvironment
Set-Alias -Name cpath -Value Copy-PathToClipboard
Set-Alias -Name dsize -Value Get-DirectorySize
Set-Alias -Name y -Value Invoke-Yazi
Set-Alias -Name cpcode -Value Copy-FileContextRecursively
Set-Alias -Name flw -Value followlink

# streaming vcs template
Set-Alias -Name istm -Value Import-StreamingTemplatesModules
Set-Alias -Name ctot -Value ConvertTo-ObsTemplate
Set-Alias -Name cfot -Value ConvertFrom-ObsTemplate
Set-Alias -Name ctdt -Value ConvertTo-StreamDeckTemplate
Set-Alias -Name cfdt -Value ConvertFrom-StreamDeckTemplate
Set-Alias -Name ctbt -Value ConvertTo-StreamerBotTemplate
Set-Alias -Name cfbt -Value ConvertFrom-StreamerBotTemplate

# configs quick edit
Set-Alias -Name rel -Value Update-Profile
Set-Alias -Name cfg -Value Edit-Profile
Set-Alias -Name wzcfg -Value Edit-WeztermProfile
Set-Alias -Name lgcfg -Value Edit-LazygitConfig
Set-Alias -Name gitcfg -Value Edit-GitConfig

# navigation and file management
Set-Alias -Name zz -Value Set-LastDirectory
Set-Alias -Name lks -Value Set-SymlinkSource
Set-Alias -Name lkt -Value Set-SymlinkTarget
Set-Alias -Name fx -Value fcut
Set-Alias -Name fcp -Value fcopy
set-Alias -Name fp -Value fpaste

## Exec aliases
Set-Alias -Name vi -Value nvim
Set-Alias -Name ex -Value explorer
Set-Alias -Name d -Value dir
Set-Alias -Name wh -Value where.exe
Set-Alias wezdev "C:\Users\ville\myfiles\git-repos\wezterm\target\release\wezterm.exe"
Set-Alias -Name cc -Value claude

## Path additions
$pathsToAdd = @(
  "$env:DOTFILES_PATH\windows\batch"
  "$HOME\myfiles\programs\PROGRAMS_ON_PATH"
  "C:\Program Files\Git\bin"
  "$env:LOCALAPPDATA\nvim-data\mason\bin"
  "$env:APPDATA\Python\Python313\Scripts"
)

foreach ($path in $pathsToAdd) {
  if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) {
    $env:PATH += ";$path"
  }
}

## Vi mode options
$OnViModeChange = [scriptblock]{
  if ($args[0] -eq 'Command') {
    # Set the cursor to a steady block.
    Write-Host -NoNewLine "`e[2 q"
  } else {
    # Set the cursor to a steady line.
    Write-Host -NoNewLine "`e[6 q"
  }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $OnViModeChange

# Set initial mode
$global:_LastViMode = 'Insert'
Write-Host -NoNewLine "`e[6 q"

## PSReadLine options
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineKeyHandler -Chord 'U' -Function Redo -ViMode Command
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord -ViMode Insert
Set-PSReadLineKeyHandler -Key 'RightArrow' -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Alt-;' -Function AcceptSuggestion
Remove-PSReadLineKeyHandler Ctrl+d
Remove-PSReadLineKeyHandler Ctrl+u
Remove-PSReadLineKeyHandler Ctrl+y
Remove-PSReadLineKeyHandler Ctrl+l

Set-PSReadLineKeyHandler -Key Ctrl+d -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('exit')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# used with windows/pwsh/modules/essentials/prompt.psm1
Set-Alias -Name clear -Value Clear-AndPutPromptAtBottom
Set-PSReadLineKeyHandler -Chord Ctrl+x -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('clear')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# used with windows/pwsh/modules/navigate/LocationHistory.psm1
Set-PSReadLineKeyHandler -Key Ctrl+p -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('cdprev')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+n -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('cdnext')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# do not add lines containing cmdkey password to history
Set-PSReadLineOption -AddToHistoryHandler {
  param($line)
  if ($line -match "cmdkey.*pass:") {
    return $false
  }
  return $true
}

## Fzf options
Initialize-PsFzf

## Prompt and zoxide (must load last, in this order: zoxide wraps the starship prompt)
Initialize-Starship
Initialize-Zoxide
