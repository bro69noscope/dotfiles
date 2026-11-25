## Profile and config functions
function Update-Profile {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.SendKeys]::SendWait(". $")
  [System.Windows.Forms.SendKeys]::SendWait("PROFILE")
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
}

function Edit-Profile {
  nvim $PROFILE
}

function Set-RegistryEnvVars {
  $vars = & "$env:DOTFILES_PATH\windows\env\registry-env-vars.ps1"

  foreach ($var in $vars.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'User')
    Set-Item -Path "env:$($var.Key)" -Value $var.Value # current session too
    Write-Host "$($var.Key) = $($var.Value)"
  }
}

function Edit-WeztermProfile {
  nvim "$env:DOTFILES_PATH\wezterm\wezterm.lua"
}

function Edit-LazygitConfig {
  nvim "$env:DOTFILES_PATH\lazygit-config.yml"
}

function Edit-GitConfig {
  git config --global -e
}

function Edit-KanataConfig {
  nvim "$env:DOTFILES_PATH\kanata.kbd"
}

# List all dot-sourced scripts in the current session
function listdotsourced{
  (Get-History | Where-Object { $_.CommandLine -match '^\.\s+' }).CommandLine
}
