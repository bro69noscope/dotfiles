param(
  [string]$Repo = 'git@github.com:bro69noscope/dotfiles.git',
  [string]$Branch = 'main',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Files = @(
  'hotkeys.json'
)

$Vault = Split-Path $PSScriptRoot
$Obsidian = Join-Path $Vault '.obsidian'
$Listed = Get-Content (Join-Path $PSScriptRoot 'plugins.json') | ConvertFrom-Json
$Enabled = Get-Content (Join-Path $Obsidian 'community-plugins.json') | ConvertFrom-Json
$Items = $Files + ($Listed | ForEach-Object { "plugins/$_" })

$Clone = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-$([guid]::NewGuid())"

try {
  git clone --quiet --depth 1 --filter=blob:none --sparse --branch $Branch $Repo $Clone
  if ($LASTEXITCODE) {
    throw "git clone failed ($LASTEXITCODE)"
  }

  git -C $Clone sparse-checkout set --no-cone ($Items | ForEach-Object { "/obsidian/config/$_" })
  if ($LASTEXITCODE) {
    throw "git sparse-checkout failed ($LASTEXITCODE)"
  }

  $Config = Join-Path $Clone 'obsidian/config'

  foreach ($Item in $Items) {
    $Src = Join-Path $Config $Item
    if (-not (Test-Path $Src)) {
      Write-Warning "$Item not found in dotfiles"
      continue
    }

    # Obsidian removes a plugin from this list when the plugin is missing at startup.
    $Id = $Item -replace '^plugins/', ''
    if ($Id -ne $Item -and $Id -notin $Enabled) {
      Write-Warning "Plugin $Id not enabled in Obsidian: enable it in Settings > Community plugins"
    }

    Get-ChildItem $Src -Recurse -File | ForEach-Object {
      $Rel = [IO.Path]::GetRelativePath($Config, $_.FullName) -replace '\\', '/'
      $Out = Join-Path $Obsidian $Rel
      if (-not $Force -and (Test-Path $Out)) {
        return
      }

      New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
      Copy-Item $_.FullName $Out
      Write-Host "added $Rel"
    }
  }
} finally {
  if (Test-Path $Clone) {
    Remove-Item -Recurse -Force $Clone
  }
}
