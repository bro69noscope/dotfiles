## Location functions
function dl {
  Set-location "$env:USERPROFILE\Downloads"
}

function ahk {
  Set-Location "$env:DOTFILES_PATH\windows\autohotkey"
}

function vidata {
  Set-Location "$env:LOCALAPPDATA\nvim-data"
}

function vid {
  Set-Location "$env:DOTFILES_PATH\nvim-config3.0" # better than if in $HOME for lazydev nvim plugin usage
}

function vir {
  nvim -u "$env:DOTFILES_PATH\nvim-config3.0\repro.lua" @args
}

function roam {
  Set-Location "$env:APPDATA"
}

function loc {
  Set-Location "$env:LOCALAPPDATA"
}

function dot {
  Set-Location "$env:DOTFILES_PATH"
}

function my {
  Set-Location "$HOME\myfiles"
}

function sce {
  Set-Location "$env:APPDATA\obs-studio\basic\scenes"
}

function aoe {
  Set-Location "$env:STREAMING_REPO_PATH\external\obs\version-control\scenes\collection_aoe2"
}

function temp {
  Set-Location "$env:TEMP"
}

# List all dot-sourced scripts in the current session
function listdotsourced{
  (Get-History | Where-Object { $_.CommandLine -match '^\.\s+' }).CommandLine
}

# directory sorted by last access time
function dr {
  Get-ChildItem @args | Sort-Object LastAccessTime
}

# follow a symlink to its target directory
function follow {
  param($path)
  $target = (Get-Item $path).Target
  Set-Location (Split-Path $target)
}

# allow to cd to a file path which will cd to the parent directory instead
function cd {
  param([string]$Path = ".")

  if (Test-Path $Path -PathType Leaf) {
    Set-Location (Split-Path $Path -Parent)
  } else {
    Set-Location $Path
  }
}

function Update-Profile {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.SendKeys]::SendWait(". $")
  [System.Windows.Forms.SendKeys]::SendWait("PROFILE")
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
}

function wslbackup {
  wsl --terminate Arch; wsl --export Arch "$env:USERPROFILE\OneDrive\Backups\wsl\Arch-$(Get-Date -Format yyyyMMdd-HHmmss).tar"
}

function Edit-Profile {
  nvim $PROFILE
}

function Edit-WeztermProfile {
  nvim "$env:DOTFILES_PATH\.wezterm.lua"
}

function Edit-LazygitConfig {
  nvim "$env:DOTFILES_PATH\lazygit-config.yml"
}

function Edit-GitConfig {
  git config --global -e
}

function Edit-KanataConfig {
  nvim "$env:DOTFILES_PATH\kanata.kbd"
}

function lt {
  eza --icons -lT $args
}

function l {
  eza --icons -l $args
}

function Clear-AndPutPromptAtBottom {
  $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
  Clear-Host
  $consoleHeight = $host.UI.RawUI.WindowSize.Height
  Write-Host "$([char]27)[${consoleHeight}B" -NoNewline
}

function Hide-WindowsTaskbar {
  Start-Process -FilePath "nircmd.exe" -ArgumentList "win trans class Shell_TrayWnd 256" -NoNewWindow
}

function Show-WindowsTaskbar {
  Start-Process -FilePath "nircmd.exe" -ArgumentList "win trans class Shell_TrayWnd 255" -NoNewWindow
}

function Set-LastDirectory {
  z "-"
}

# copy/paste functions for files and directories
$global:fileClipboard = $null
$global:fileClipboardMode = $null

function fcut {
  $global:fileClipboard = Get-Item $args[0]
  $global:fileClipboardMode = "cut"
}

function fcopy {
  $global:fileClipboard = Get-Item $args[0]
  $global:fileClipboardMode = "copy"
}

function fpaste {
  if (-not $global:fileClipboard) {
    Write-Error "Clipboard is empty."
    return
  }

  switch ($global:fileClipboardMode) {
    "cut" {
      Move-Item $global:fileClipboard.FullName -Destination .
    }
    "copy" {
      Copy-Item $global:fileClipboard.FullName -Destination . -Recurse
    }
    default {
      Write-Error "Unknown clipboard mode."
    }
  }
}

function Set-PythonPath {
  $env:PYTHONPATH = (Get-Location).Path
  Write-Output "PYTHONPATH set to: $env:PYTHONPATH"
}

function Enter-MegaScriptEnvironment {
  Set-Location $env:STREAMING_REPO_PATH
  Set-PythonPath
  .\.venv\Scripts\activate
}

function Copy-PathToClipboard {
  param(
    [string]$Path = "."
  )
  $fullPath = (Get-Item $Path).FullName
  $fullPath | Set-Clipboard
  Write-Host "Copied to clipboard: $fullPath"
}

function Get-DirectorySize {
  Get-ChildItem | Select-Object Name, @{
    Name = "Type"
    Expression = {
      if ($_.PSIsContainer) {
        "Directory"
      } else {
        "File"
      }
    }
  }, @{
    Name = "Size (MB)"
    Expression = {
      if ($_.PSIsContainer) {
        # If the item is a directory, calculate the total size of its contents
        [math]::Round((Get-ChildItem $_.FullName -Recurse -Force | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
      } else {
        # If the item is a file, return its size
        [math]::Round($_.Length / 1MB, 2)
      }
    }
  } | Format-Table -AutoSize
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

function Import-StreamingTemplatesModules {
  if (-not $env:STREAMING_REPO_PATH) {
    throw "STREAMING_REPO_PATH environment variable is not set"
  }

  $repo = $env:STREAMING_REPO_PATH
  $modules = @{
    OBS = Join-Path $repo `
      "external\obs\version-control\obs-templater.psm1"

    StreamDeck = Join-Path $repo `
      "external\streamdeck\version-control\streamdeck-templater.psm1"

    StreamerBot = Join-Path $repo `
      "external\streamerbot\version-control\streamerbot-templater.psm1"
  }

  foreach ($module in $modules.GetEnumerator()) {
    if (-not (Test-Path $module.Value)) {
      throw "$($module.Key) module not found at: $($module.Value)"
    }

    Import-Module $module.Value -Force -Global
  }

  Write-Host "Streaming tools loaded!" -ForegroundColor Green
}

function Test-IsBinaryFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,
    [int]$SampleSize = 4096
  )
  try {
    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    $read = [Math]::Min($bytes.Length, $SampleSize)
    for ($i = 0; $i -lt $read; $i++) {
      if ($bytes[$i] -eq 0) {
        return $true
      }
    }
    return $false
  } catch {
    Write-Warning "Failed reading '$Path': $($_.Exception.Message)"
    return $true
  }
}


function Copy-FileContextRecursively {
  param(
    [Parameter(Position=0)]
    [string]$Path = ".",

    [Parameter(Position=1)]
    [string]$Filter = "*",

    [Alias("d")]
    [switch]$StructureOnly,

    [Alias("x")]
    [string[]]$Exclude
  )

  $output = @()

  # Build fd exclude args
  $fdExcludeArgs = @()
  if ($Exclude) {
    foreach ($e0 in $Exclude) {
      $e = ($e0 ?? "").Trim()
      if ($e -eq "") {
        continue
      }

      # 1. Remove leading .\ or ./
      $e = $e -replace '^[.][\\/]+', ''

      # 2. Normalize slashes to forward slash (fd glob style)
      $e = $e -replace '\\', '/'

      # 3. If it ends with /, treat as directory
      if ($e.EndsWith('/')) {
        $e = $e.TrimEnd('/')
        $e = "$e/**"
      }

      if ($e -ne "") {
        $fdExcludeArgs += @("-E", $e)
      }
    }
  }


  # Directory structure
  $output += "=== DIRECTORY STRUCTURE ==="
  $output += ""
  $output += fd . $Path @fdExcludeArgs
  $output += ""

  # File contents (skip if StructureOnly is specified)
  if (-not $StructureOnly) {
    $output += "=== FILE CONTENTS ==="
    $output += ""

    $files = fd -t f . $Path @fdExcludeArgs
    foreach ($file in $files) {
      $output += ""
      $output += "━━━ $file ━━━"
      $output += ""

      if (Test-IsBinaryFile $file) {
        $output += "[binary file skipped]"
      } else {
        try {
          $output += Get-Content $file -Raw -ErrorAction Stop
        } catch {
          $output += "[unreadable file]"
        }
      }
      $output += ""
    }

    $fileCount = $files.Count
    $message = "✓ Copied structure and contents of $fileCount file(s) from '$Path' to clipboard"
  } else {
    $message = "✓ Copied directory structure from '$Path' to clipboard"
  }

  $output -join "`n" | Set-Clipboard
  Write-Host $message
}

$script:LinkSource = $null
function Set-SymlinkSource {
  param(
    [string]$Path = "."
  )

  $script:LinkSource = (Resolve-Path $Path).Path
  Write-Host "Stored: $script:LinkSource"
}

function Set-SymlinkTarget {
  param(
    [string]$Target = "."
  )

  if (-not $script:LinkSource) {
    throw "No source stored. Run Set-SymlinkSource first."
  }

  $source = $script:LinkSource
  $target = (Resolve-Path $Target).Path
  $script:LinkSource = $null

  if (Test-Path $source) {
    Remove-Item $source -Recurse -Force
  }

  New-Item -ItemType SymbolicLink -Path $source -Target $target | Out-Null

  Write-Host "$source -> $target"
}
