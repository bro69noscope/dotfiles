# streamdeck locations
function aoed {
  Set-Location "$env:STREAMDECK_CFG_PATH\08F1CB5E-CA39-47F0-9924-8D181F508A8C.sdProfile\"
}

function ftpd {
  Set-Location "$env:STREAMDECK_CFG_PATH\E6C31B42-9341-4D54-9C06-A5227FE9199C.sdProfile\"
}

# streamerbot locations
function strp {
  Set-Location `
    "$env:MYFILES_PATH\streaming-programs\streamerbot-portable-production\Streamer.bot\data"
}

function strf {
  Set-Location `
    "$env:MYFILES_PATH\streaming-programs\streamerbot-portable-ftp\Streamer.bot\data"
}

# obs locations
function obsp {
  Set-Location "$env:OBS_STUDIO_PRODUCTION_CFG_PATH"
}

function obsf {
  Set-Location "$env:OBS_STUDIO_FTP_CFG_PATH"
}

# vcs repository locations
function vcsd {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\streamdeck\version-control\vcdata"
}

function vcsb {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\streamerbot\version-control\vcdata"
}

function vcso {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\obs\version-control\vcdata"
}

# orchestrator wrappers
function ctat {
  [CmdletBinding()]
  param(
    [switch]$Backup,
    [switch]$Import,
    [Alias('nogen')] [switch]$SkipScopedGeneration,
    [Alias('deck')] [switch]$StreamDeck,
    [switch]$Obs,
    [Alias('sbot')] [switch]$Streamerbot
  )
  Invoke-VcsTemplating -Direction To @PSBoundParameters
}

function cfat {
  [CmdletBinding()]
  param(
    [switch]$Backup,
    [switch]$Import,
    [Alias('nogen')] [switch]$SkipScopedGeneration,
    [Alias('deck')] [switch]$StreamDeck,
    [switch]$Obs,
    [Alias('sbot')] [switch]$Streamerbot
  )
  Invoke-VcsTemplating -Direction From @PSBoundParameters
}

function Import-StreamingTemplatesModules {
  if (-not $env:BRO_NLLS_REPO_PATH) {
    throw "BRO_NLLS_REPO_PATH environment variable is not set"
  }

  $repo = $env:BRO_NLLS_REPO_PATH
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
