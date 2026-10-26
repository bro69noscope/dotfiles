param(
  [switch]$Remove
)

if (-not $env:DOTFILES_PATH) {
  throw "DOTFILES_PATH is not set"
}
if (-not $env:STREAMING_REPO_PATH) {
  throw "STREAMING_REPO_PATH is not set"
}

$link = Join-Path $env:DOTFILES_PATH "windows\autohotkey\utils-script\streaming-ahk"
$target = Join-Path $env:STREAMING_REPO_PATH "external\ahk"

$existing = Get-Item $link -Force -ErrorAction SilentlyContinue

if ($existing -and $existing.LinkType -ne "Junction") {
  throw "$link exists and is not a junction, refusing to touch it"
}

if ($existing) {
  # Directory.Delete on a junction removes only the link, never the target's contents
  [System.IO.Directory]::Delete($link)
  Write-Host "Removed junction $link"
}

if ($Remove) {
  return
}

if (-not (Test-Path $target)) {
  throw "Target not found: $target (is STREAMING_REPO_PATH correct?)"
}

New-Item -ItemType Junction -Path $link -Target $target | Out-Null
Write-Host "Linked $link -> $target"
