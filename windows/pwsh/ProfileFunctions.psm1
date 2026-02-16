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
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Item
  )
  $fullPath = (Get-Item $Item).FullName
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
  # Our yazi invocation with directory changing support
  $tmp = [System.IO.Path]::GetTempFileName()
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
  }
  Remove-Item -Path $tmp
}

function Import-StreamingModules {
  if (-not $env:STREAMING_REPO_PATH) {
    throw "STREAMING_REPO_PATH environment variable is not set"
  }

  $obsModule = "$env:STREAMING_REPO_PATH\external\obs\version-control\obs-templater.psm1"
  $streamDeckModule = "$env:STREAMING_REPO_PATH\external\streamdeck\version-control\streamdeck-templater.psm1"

  if (-not (Test-Path $obsModule)) {
    throw "OBS module not found at: $obsModule"
  }

  if (-not (Test-Path $streamDeckModule)) {
    throw "StreamDeck module not found at: $streamDeckModule"
  }

  Import-Module $obsModule -Force -Global -ErrorAction Stop
  Import-Module $streamDeckModule -Force -Global -ErrorAction Stop

  Write-Host "Streaming tools loaded!" -ForegroundColor Green
}

function Test-IsBinaryFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [int]$SampleSize = 4096
  )

  try {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
      $buffer = New-Object byte[] $SampleSize
      $read = $fs.Read($buffer, 0, $buffer.Length)
      return ($buffer[0..($read-1)] -contains 0)
    } finally {
      $fs.Dispose()
    }
  } catch {
    # If we can’t read it safely, assume binary
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
        $output += Get-Content $file -Raw
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

