$dotfilesConfig = @{

  "PowerShell profile" = @{
    "source" = "$env:DOTFILES_PATH\windows\pwsh\Microsoft.PowerShell_profile.ps1"
    "target" = "$HOME\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
  }

  "Git config" = @{
    "source" = "$env:DOTFILES_PATH\.gitconfig"
    "target" = "$HOME\.gitconfig"
  }

  "Lazygit config" = @{
    "source" = "$env:DOTFILES_PATH\lazygit-config.yml"
    "target" = "$HOME\AppData\Local\lazygit\config.yml"
  }

  "Alacritty config" = @{
    "source" = "$env:DOTFILES_PATH\alacritty.toml"
    "target" = "$HOME\AppData\Roaming\alacritty\alacritty.toml"
  }

  "VS Code keybinds" = @{
    "source" = "$env:DOTFILES_PATH\vscode\keybindings.json"
    "target" = "$HOME\AppData\Roaming\Code\User\keybindings.json"
  }

  "VS Code settings" = @{
    "source" = "$env:DOTFILES_PATH\vscode\settings.json"
    "target" = "$HOME\AppData\Roaming\Code\User\settings.json"
  }

  "Wezterm config" = @{
    "source" = "$env:DOTFILES_PATH\.wezterm.lua"
    "target" = "$HOME\.wezterm.lua"
  }

  "Nvim config" = @{
    "source"  = "$env:DOTFILES_PATH\nvim-config3.0"
    "target" = "$HOME\AppData\Local\nvim\"
  }

  "Starship config" = @{
    "source"  = "$env:DOTFILES_PATH\starship.toml"
    "target" = "$HOME\.config\starship.toml"
  }

  "Kanata config" = @{
    "source"  = "$env:DOTFILES_PATH\kanata.kbd"
    "target" = "$HOME\AppData\Roaming\kanata\kanata.kbd"
  }

  # Yazi: cannot symlink the whole folder because of interactions with the package manager
  "Yazi general config" = @{
    "source"  = "$env:DOTFILES_PATH\yazi-config\yazi.toml"
    "target" = "$HOME\AppData\Roaming\yazi\config\yazi.toml"
  }

  "Yazi package" = @{
    "source"  = "$env:DOTFILES_PATH\yazi-config\package.toml"
    "target" = "$HOME\AppData\Roaming\yazi\config\package.toml"
  }

  "Yazi theme" = @{
    "source"  = "$env:DOTFILES_PATH\yazi-config\theme.toml"
    "target" = "$HOME\AppData\Roaming\yazi\config\theme.toml"
  }

  "Yazi keymap" = @{
    "source"  = "$env:DOTFILES_PATH\yazi-config\keymap.toml"
    "target" = "$HOME\AppData\Roaming\yazi\config\keymap.toml"
  }

  "Yazi init.lua" = @{
    "source"  = "$env:DOTFILES_PATH\yazi-config\init.lua"
    "target" = "$HOME\AppData\Roaming\yazi\config\init.lua"
  }
}


function Sync-Symlinks {
  foreach ($item in $dotfilesConfig.GetEnumerator()) {
    $source = $item.Value.source
    $target = $item.Value.target

    if (-not (Test-Path $source)) {
      Write-Host "Source not found: $source. Skipping."
      continue
    }

    $isDirectory = (Get-Item $source) -is [System.IO.DirectoryInfo]

    if (Test-Path $target) {
      # Check if target is already a symlink pointing to our source
      $existingLink = Get-Item $target -ErrorAction SilentlyContinue
      if ($existingLink.LinkType -eq "SymbolicLink" -and $existingLink.Target -eq $source) {
        Write-Host "Symlink already exists and is correct for $($item.Key). Skipping."
        continue
      }
      Remove-Item $target -Force -Recurse
    }

    if ($isDirectory) {
      $command = "cmd /c mklink /D `"$target`" `"$source`""
    } else {
      $command = "cmd /c mklink `"$target`" `"$source`""
    }

    $result = Invoke-Expression $command
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Linked $($item.Key): $target -> $source" -ForegroundColor Green
    } else {
      Write-Host "Failed to link $($item.Key): $target -> $source" -ForegroundColor Red
      Write-Host "Error: $result" -ForegroundColor Red
    }
  }
}

# Don't run automatically, require explicit execution
Write-Host "To sync dotfiles symlinks, run the Sync-Symlinks function."
