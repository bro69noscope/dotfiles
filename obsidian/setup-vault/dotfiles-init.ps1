param(
  [string]$Repo = 'git@github.com:bro69noscope/dotfiles.git',
  [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

if (-not ($env:DOTFILES_PATH)) {
  throw "DOTFILES_PATH environment variable is not set"
}

$PathSegments = @('obsidian', 'setup-vault')
$SparsePattern = "/$($PathSegments -join '/')/"

$Scripts = @('fetch-vault.ps1', 'push-vault.ps1', 'paths.ps1')

$Clone = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-$([guid]::NewGuid())"

try {
  git clone --quiet --depth 1 --filter=blob:none --sparse --branch $Branch $Repo $Clone
  if ($LASTEXITCODE) {
    throw "git clone failed ($LASTEXITCODE)"
  }

  git -C $Clone sparse-checkout set --no-cone $SparsePattern
  if ($LASTEXITCODE) {
    throw "git sparse-checkout failed ($LASTEXITCODE)"
  }

  foreach ($Script in $Scripts) {
    $Out = Join-Path $PSScriptRoot $Script
    if (Test-Path $Out) {
      continue
    }

    $Src = Join-Path $Clone @PathSegments $Script
    if (-not (Test-Path $Src)) {
      Write-Warning "$Script not found in dotfiles"
      continue
    }

    Copy-Item $Src $Out
    Write-Host "added $Script"
  }
} finally {
  if (Test-Path $Clone) {
    Remove-Item -Recurse -Force $Clone
  }
  if (-not (Test-Path $LocalPath)) {
    New-Item -ItemType File -Force $LocalPath | Out-Null
  }
}
