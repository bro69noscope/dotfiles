## Clipboard functions
function Copy-PathToClipboard {
  param(
    [string]$Path = ".",

    [switch]$Relative
  )

  $resolvedPath = if ($Relative) {
    Resolve-Path -Path $Path -Relative
  } else {
    (Get-Item $Path).FullName
  }

  $resolvedPath | Set-Clipboard
  Write-Host "Copied to clipboard: $resolvedPath"
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
