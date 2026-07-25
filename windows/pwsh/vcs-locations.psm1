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
  Set-Location "$env:STREAMING_REPO_PATH\external\streamdeck\version-control\vcdata"
}

function vcsb {
  Set-Location "$env:STREAMING_REPO_PATH\external\streamerbot\version-control\vcdata"
}

function vcso {
  Set-Location "$env:STREAMING_REPO_PATH\external\obs\version-control\vcdata"
}
