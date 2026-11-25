# Paths in the dotfiles repo.
$SetupSegments = @('obsidian', 'setup-vault')
$ConfigSegments = @('obsidian', 'config')

# Paths in the vault.
$Vault = Split-Path $PSScriptRoot
$Obsidian = Join-Path $Vault '.obsidian'
if (-not (Test-Path $Obsidian -PathType Container)) {
  throw "Not a vault: $Vault has no .obsidian folder. Keep this script in <vault>/setup-vault/."
}

$LocalPath = Join-Path $PSScriptRoot 'local-plugins.json'
