param(
  [string]$Dotfiles = "$HOME/myfiles/dotfiles"
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'paths.ps1')

$Config = Join-Path $Dotfiles @ConfigSegments
if (-not (Test-Path $Config -PathType Container)) {
  throw "Not the dotfiles repo: $Config does not exist. Give the repo root with -Dotfiles."
}

$Shared = Get-Content (Join-Path $Dotfiles @SetupSegments 'shared.json') | ConvertFrom-Json
$VaultOnly = @($Shared.vaultOnly)

$Local = @()
if (Test-Path $LocalPath) {
  $Local = @(Get-Content $LocalPath | ConvertFrom-Json)
}

$Plugins = Get-ChildItem (Join-Path $Obsidian 'plugins') -Directory -Name |
  Where-Object { $_ -notin $Local }

$Items = @($Shared.files) + ($Plugins | ForEach-Object { "plugins/$_" })

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

  Get-ChildItem (Join-Path $Config $Item) -Recurse -File | ForEach-Object {
    $Rel = [IO.Path]::GetRelativePath($Config, $_.FullName) -replace '\\', '/'
    if (-not $Keep[$Rel]) {
      Remove-Item $_.FullName
    }
  }
}

git -C $Dotfiles status --short -- ($ConfigSegments -join '/')
