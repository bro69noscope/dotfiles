## File listing and file management functions
# fd with dir style output
function fdd {
  fd @args | Get-ChildItem
}

# directory sorted by last access time
function dr {
  Get-ChildItem @args | Sort-Object LastWriteTime
}

function lt {
  eza --icons -lT $args
}

function l {
  eza --icons -l $args
}

function lr {
  eza --icons -l --sort=modified $args
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

# copy/paste functions for files and directories, available across PowerShell sessions
$script:FileClipboardPath = Join-Path $env:TEMP 'pwsh-file-clipboard.json'

function fcut {
  param([Parameter(Mandatory)][string]$Path)
  $item = Get-Item -LiteralPath $Path -ErrorAction Stop
  [pscustomobject]@{
    FullName = $item.FullName
    Mode = 'cut'
  } | ConvertTo-Json | Set-Content -LiteralPath $script:FileClipboardPath -Encoding utf8
}

function fcopy {
  param([Parameter(Mandatory)][string]$Path)
  $item = Get-Item -LiteralPath $Path -ErrorAction Stop
  [pscustomobject]@{
    FullName = $item.FullName
    Mode = 'copy'
  } | ConvertTo-Json | Set-Content -LiteralPath $script:FileClipboardPath -Encoding utf8
}

function fpaste {
  param([string]$NewName = $null)

  if (-not (Test-Path $script:FileClipboardPath)) {
    Write-Error "Clipboard is empty."
    return
  }

  $clip = Get-Content -LiteralPath $script:FileClipboardPath -Raw | ConvertFrom-Json

  if (-not (Test-Path -LiteralPath $clip.FullName)) {
    Write-Error "Clipboard source no longer exists: $($clip.FullName)"
    return
  }

  $destination = if ($NewName) {
    Join-Path (Get-Location) $NewName
  } else {
    '.'
  }

  $destExists = Test-Path -LiteralPath $destination

  switch ($clip.Mode) {
    'cut' {
      Move-Item -LiteralPath $clip.FullName -Destination $destination -Confirm:$destExists
      if (-not (Test-Path -LiteralPath $clip.FullName)) {
        # source is gone, so the move actually happened
        Remove-Item -LiteralPath $script:FileClipboardPath -ErrorAction SilentlyContinue
      }
    }
    'copy' {
      Copy-Item -LiteralPath $clip.FullName -Destination $destination -Recurse -Confirm:$destExists
    }
    default {
      Write-Error "Unknown clipboard mode."
    }
  }
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
