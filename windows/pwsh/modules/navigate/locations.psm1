## Location functions
function csh {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\streamerbot\version-control\vcdata\common\csharp"
}

function alerts {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\html\alerts-overlays"
}

function feedapp {
  Set-Location "$env:BRO_NLLS_REPO_PATH\external\StreamFeedApp"
}

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
  Set-Location "$env:NVIM_CONFIG_PATH" # better than if in $HOME for lazydev nvim plugin usage
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

function deck {
  Set-Location "$env:APPDATA\Elgato\StreamDeck\ProfilesV3"
}

function temp {
  Set-Location "$env:TEMP"
}
