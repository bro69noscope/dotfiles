function genico {
  param([string]$path)
  $repoRoot = $env:BRO_NLLS_REPO_PATH
  pyenv $repoRoot
  & python `
    "$repoRoot\external\streamdeck\utils\generate-icons\main.py"
}

