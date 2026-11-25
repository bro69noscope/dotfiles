## External program wrappers
function vir {
  nvim -u "$env:NVIM_CONFIG_PATH\repro.lua" @args
}

# follow checked out worktrees to their root directories
function lg {
  $env:LAZYGIT_NEW_DIR_FILE = "$env:USERPROFILE\.lazygit\newdir"
  lazygit @args
  if (Test-Path $env:LAZYGIT_NEW_DIR_FILE) {
    Set-Location (Get-Content $env:LAZYGIT_NEW_DIR_FILE)
    Remove-Item -Force $env:LAZYGIT_NEW_DIR_FILE
  }
}

# Run neovide, only 1 instance
function ne {
  $procs = Get-Process neovide -ErrorAction SilentlyContinue

  if ($procs) {
    $info = $procs | ForEach-Object {
      "  PID: $($_.Id)`n  Path: $($_.Path)"
    }
    Write-Error "Neovide is already running:`n$($info -join "`n")"
    return
  }
  neovide @args
}

function Invoke-Yazi {
  # Our yazi invocation with directory changing support + zoxide population with exit location
  $tmp = [System.IO.Path]::GetTempFileName()
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    zoxide add $cwd
  }
  Remove-Item -Path $tmp
}

function wslbackup {
  wsl --terminate Arch; wsl --export Arch "$env:USERPROFILE\OneDrive\Backups\wsl\Arch-$(Get-Date -Format yyyyMMdd-HHmmss).tar"
}

function rerere {
  param([string]$Range = 'main..HEAD')
  sh "$HOME/rerere-train.sh" (git rev-list --merges $Range)
}
