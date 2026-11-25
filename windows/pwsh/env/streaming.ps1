# Needs MYFILES_PATH from paths.ps1
$env:STREAMER_BOT_PRODUCTION_PATH= Join-Path $env:MYFILES_PATH `
  "streaming-programs\streamerbot-portable-production\Streamer.bot"

$env:STREAMER_BOT_FTP_PATH= Join-Path $env:MYFILES_PATH `
  "streaming-programs\streamerbot-portable-ftp\Streamer.bot"

$env:OBS_STUDIO_PRODUCTION_CFG_PATH= "$env:APPDATA\obs-studio"

$env:OBS_STUDIO_FTP_CFG_PATH= Join-Path $env:MYFILES_PATH `
  "streaming-programs\obs-studio-portable-ftp\obs-studio\config\obs-studio"

$env:OBS_STUDIO_VCAM_CFG_PATH= Join-Path $env:MYFILES_PATH `
  "streaming-programs\obs-studio-portable-vcam\obs-studio\config\obs-studio"

$env:STREAMDECK_CFG_PATH= "$env:APPDATA\Elgato\StreamDeck\ProfilesV3"
