$script:LocationHistory = [System.Collections.Generic.List[string]]::new()
$script:LocationIndex = -1
$script:MaxHistorySize = 500

function Set-Location {
  [CmdletBinding(DefaultParameterSetName = 'Path')]
  param(
    [Parameter(Position = 0, ParameterSetName = 'Path', ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string]$Path,

    [Parameter(ParameterSetName = 'LiteralPath', ValueFromPipelineByPropertyName)]
    [Alias('PSPath')]
    [string]$LiteralPath,

    [pscredential]$Credential,

    [switch]$Force,

    [switch]$PassThru
  )

  process {
    $target = if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
      $LiteralPath
    } else {
      $Path
    }

    $resolveParams = @{
      ErrorAction = 'Stop'
    }
    if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
      $resolveParams['LiteralPath'] = $target
    } else {
      $resolveParams['Path'] = $target
    }
    $resolved = Resolve-Path @resolveParams

    $slParams = @{
      LiteralPath = $resolved.Path
      ErrorAction = 'Stop'
      PassThru    = $true   # always request it internally so we can validate success
    }
    if ($Force) {
      $slParams['Force'] = $true
    }
    if ($Credential) {
      $slParams['Credential'] = $Credential
    }

    # Actually move first; only touch history if this succeeds
    $result = Microsoft.PowerShell.Management\Set-Location @slParams

    $newPath = $result.Path

    # Skip pushing history if we're already at this location (dedup)
    $current = if ($script:LocationIndex -ge 0) {
      $script:LocationHistory[$script:LocationIndex]
    } else {
      $null
    }
    if ($newPath -ne $current) {
      if ($script:LocationIndex -lt ($script:LocationHistory.Count - 1)) {
        $script:LocationHistory.RemoveRange(
          $script:LocationIndex + 1,
          $script:LocationHistory.Count - $script:LocationIndex - 1
        )
      }
      $script:LocationHistory.Add($newPath)
      $script:LocationIndex = $script:LocationHistory.Count - 1

      # Cap history size, trimming from the front
      if ($script:LocationHistory.Count -gt $script:MaxHistorySize) {
        $overflow = $script:LocationHistory.Count - $script:MaxHistorySize
        $script:LocationHistory.RemoveRange(0, $overflow)
        $script:LocationIndex -= $overflow
      }
    }

    if ($PassThru) {
      $result
    }
  }
}

function cdprev {
  if ($script:LocationIndex -gt 0) {
    $script:LocationIndex--
    Microsoft.PowerShell.Management\Set-Location -LiteralPath $script:LocationHistory[$script:LocationIndex]
  }
}

function cdnext {
  if ($script:LocationIndex -lt ($script:LocationHistory.Count - 1)) {
    $script:LocationIndex++
    Microsoft.PowerShell.Management\Set-Location -LiteralPath $script:LocationHistory[$script:LocationIndex]
  }
}

Export-ModuleMember -Function Set-Location, cdprev, cdnext
