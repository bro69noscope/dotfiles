param(
  [string]$Dotfiles = "$HOME/myfiles/dotfiles"
)

$ErrorActionPreference = 'Stop'

$Files = @(
  'hotkeys.json'
)

# Plugin files specific to vault
$VaultOnly = @(
  'plugins/yazi-explorer/local.json'
  'plugins/yazi-explorer/text-index.json'
)

$Vault = Split-Path $PSScriptRoot
$Obsidian = Join-Path $Vault '.obsidian'
$Listed = Get-Content (Join-Path $PSScriptRoot 'plugins.json') | ConvertFrom-Json
$Items = $Files + ($Listed | ForEach-Object { "plugins/$_" })
$Config = Join-Path $Dotfiles 'obsidian/config'

foreach ($Item in $Items) {
  $Src = Join-Path $Obsidian $Item
  if (-not (Test-Path $Src)) {
    Write-Warning "$Item not found in the vault"
    continue
  }

  $Keep = @{}

  Get-ChildItem $Src -Recurse -File | ForEach-Object {
    $Rel = [IO.Path]::GetRelativePath($Obsidian, $_.FullName) -replace '\\', '/'
    if ($Rel -in $VaultOnly) {
      return
    }

    $Keep[$Rel] = $true
    $Out = Join-Path $Config $Rel
    New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
    Copy-Item $_.FullName $Out
  }

  # Remove files that the item no longer has in the vault.
  Get-ChildItem (Join-Path $Config $Item) -Recurse -File | ForEach-Object {
    $Rel = [IO.Path]::GetRelativePath($Config, $_.FullName) -replace '\\', '/'
    if (-not $Keep[$Rel]) {
      Remove-Item $_.FullName
    }
  }
}

git -C $Dotfiles status --short -- obsidian/config
