function pyenv {
  param([string]$Path = (Get-Location).Path)
  $dir = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
  while ($dir -and -not (Test-Path (Join-Path $dir '.venv\Scripts\Activate.ps1'))) {
    $dir = Split-Path $dir -Parent
  }
  if (-not $dir) {
    Write-Error "No .venv found above: $Path"
    return
  }
  . (Join-Path $dir '.venv\Scripts\Activate.ps1')
  Set-PythonPath $dir
}

function Set-PythonPath {
  param(
    [string]$Path = (Get-Location).Path
  )
  $env:PYTHONPATH = $Path
  Write-Output "PYTHONPATH set to: $env:PYTHONPATH"
}

function Enter-MegaScriptEnvironment {
  Set-Location $env:BRO_NLLS_REPO_PATH
  pyenv
}
