# follow a symlink to its target directory
function followlink {
  param($path)
  $target = (Get-Item $path).Target
  Set-Location (Split-Path $target)
}

# allow to cd to a file path which will cd to the parent directory instead
function cdf {
  param([string]$Path = ".")

  if (Test-Path $Path -PathType Leaf) {
    Set-Location (Split-Path $Path -Parent)
  } else {
    Set-Location $Path
  }
}

function Set-LastDirectory {
  z "-"
}
