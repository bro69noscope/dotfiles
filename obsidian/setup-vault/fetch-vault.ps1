param(
  [string]$Repo = 'git@github.com:bro69noscope/dotfiles.git',
  [string]$Branch = 'main',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'paths.ps1')

$Enabled = Get-Content (Join-Path $Obsidian 'community-plugins.json') | ConvertFrom-Json

$Clone = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-$([guid]::NewGuid())"

try {
  git clone --quiet --depth 1 --filter=blob:none --sparse --branch $Branch $Repo $Clone
  if ($LASTEXITCODE) {
    throw "git clone failed ($LASTEXITCODE)"
  }

  git -C $Clone sparse-checkout set --no-cone "/$($SetupSegments -join '/')/shared.json"
  if ($LASTEXITCODE) {
    throw "git sparse-checkout failed ($LASTEXITCODE)"
  }

  $Shared = Get-Content (Join-Path $Clone @SetupSegments 'shared.json') | ConvertFrom-Json

  git -C $Clone sparse-checkout add (@($Shared.files) + 'plugins/' |
      ForEach-Object { "/$($ConfigSegments -join '/')/$_" })

  if ($LASTEXITCODE) {
    throw "git sparse-checkout failed ($LASTEXITCODE)"
  }

  $Config = Join-Path $Clone @ConfigSegments
  $Plugins = Get-ChildItem (Join-Path $Config 'plugins') -Directory -Name
  $Items = @($Shared.files) + ($Plugins | ForEach-Object { "plugins/$_" })

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
