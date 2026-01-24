# Detect env
WSL_ENV=false
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  WSL_ENV=true
fi

# === WSL CONFIGURATION START ===
if $WSL_ENV; then
  # Relay ssh key (must be on top)
  source ~/bin/wsl-ssh-agent-relay.sh
  # Setting Wezterm pane user variable "in_wsl" to true
  printf "\033]1337;SetUserVar=%s=%s\007" in_wsl $(echo -n 1 | base64)
  # Fix incorrect delta color rendering
  export COLORTERM=truecolor

  # HACK: fixes no undercurl in nvim
  export TERM="wezterm"
  # NOTE: Might have to build the .terminfo file with:
  # tempfile=$(mktemp) \
    # && curl -o $tempfile https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    # && tic -x -o ~/.terminfo $tempfile \
    # && rm $tempfile
fi
# === WSL CONFIGURATION END ===

# Update starship config for WSL mounted path module
# ~/bin/update-starship-config.sh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Get wezterm font size from environment variable if available
if command -v powershell.exe >/dev/null 2>&1; then
  export WEZTERM_FONT_SIZE=$(powershell.exe -Command "echo \$env:WEZTERM_FONT_SIZE" 2>/dev/null | tr -d '\r')
fi

# Basic environment setup
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export DOTFILES="$HOME/dotfiles"
unsetopt BEEP
export FZF_DEFAULT_OPTS='--layout=reverse --height=40% --preview-window=hidden'

# case insensitive completions
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Terminal position setup
printf '\n%.0s' {1..$LINES}
precmd() {
  printf "\033]0;\007" # force terminal title to be empty to trigger wezterm redraw of the tab title
  [[ $LINES -gt 40 ]] && print $'\n\n\n\n\e[5A' # space prompt from terminal bottom (if term is tall enough)
}
function clear-and-put-prompt-at-bottom() {
  printf "\e[H\ec\e[${LINES}B"
}
alias clear='clear-and-put-prompt-at-bottom'

# Initialize zinit
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load important annexes
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# Load plugins here
zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit ice depth=1
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#757575"

zinit ice depth=1
zinit light zsh-users/zsh-syntax-highlighting

# Keep this down on the file to avoid bad surprises
zinit ice depth=1
zpcompinit; zpcdreplay # Makes shit not being fucking broken allegedly
zinit light Aloxaf/fzf-tab

# Configure zsh-vi-mode
function zvm_config() {
  ZVM_KEYTIMEOUT=0.5
  ZVM_ESCAPE_KEYTIMEOUT=0.001
}

function zvm_after_init() {
  zvm_bindkey viins '^p' history-search-backward
  zvm_bindkey viins '^n' history-search-forward
  zvm_bindkey viins '^r' fzf-history-widget
  bindkey '^[[C' forward-word # Right arrow
  bindkey '\e;' end-of-line # Alt-;
}

# Load FZF completion
source <(fzf --zsh)

# Locations/bin Aliases
alias dot='cd $HOME/dotfiles'
alias vid='cd $HOME/.config/nvim'
alias vidata='cd ~/.local/share/nvim/'

alias clip='xclip -selection clipboard'
alias vi='nvim'
alias vir='nvim -u repro.lua'
alias lg='lazygit'
alias wh='which'

alias l='eza --icons -l'
alias la='eza --icons -la'
alias lt='eza --icons -T'
alias lat='eza --icons -laT'

alias zf="__zoxide_zi"
alias zz="z -"

# === CUSTOM FUNCTIONS START ===
# === QUICK EDIT FUNCTIONS START ===
function edit-wezterm-profile() {
  nvim "$DOTFILES/.wezterm.lua"
}
function edit-lazygit-config() {
  nvim "$HOME/.config/lazygit/config.yml"
}
function edit-tmux-config() {
  nvim "$HOME/.tmux.conf"
}
function edit-zshrc() {
  nvim "$HOME/.zshrc"
}

# Quick Edit aliases
alias wzcfg='edit-wezterm-profile'
alias lgcfg='edit-lazygit-config'
alias tmcfg='edit-tmux-config'
alias zshcfg='edit-zshrc'
alias gitcfg='git config --global -e'

# === QUICK EDIT FUNCTIONS END ===
# === UTILITY FUNCTIONS START ===

# Copy directory structure and file contents to clipboard
cpcode() {
  local path="${1:-.}"
  local file_count=0
  {
    echo "=== DIRECTORY STRUCTURE ==="
    echo ""
    /usr/sbin/fd . "$path"
    echo ""
    echo "=== FILE CONTENTS ==="
    echo ""
    /usr/sbin/fd -t f . "$path" | while read -r file; do
      echo ""
      echo "━━━ $file ━━━"
      echo ""
      /usr/bin/cat "$file"
      echo ""
      ((file_count++))
    done
  } | /usr/sbin/xclip -selection clipboard

  # Count files after the fact since subshell doesn't preserve variables
  file_count=$(/usr/sbin/fd -t f . "$path" | /usr/bin/wc -l)
  echo "✓ Copied structure and contents of $file_count file(s) from '$path' to clipboard"
}
compdef _path_files cpcode

# Python environment setup
function set_python_path() {
  export PYTHONPATH="$(pwd)"
  echo "PYTHONPATH set to: $PYTHONPATH"
}

function enter_megascript_environment() {
  cd "$HOME/woertsposzibllen4me"
  set_python_path
  source ./.venv/bin/activate
}

# Copy path to clipboard
function copy-path-to-clipboard() {
  if [ -z "$1" ]; then
    echo "Error: Please provide a file or directory path"
    return 1
  fi
  fullPath=$(realpath "$1" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: File or directory not found"
    return 1
  fi
  if command -v xclip &>/dev/null; then
    echo -n "$fullPath" | xclip -selection clipboard
  elif command -v xsel &>/dev/null; then
    echo -n "$fullPath" | xsel -b
  else
    echo "Error: Please install xclip or xsel"
    return 1
  fi
  echo "Copied to clipboard: $fullPath"
}

# Yazi file navigation
function lf() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

alias y='lf'

# Utility functions aliases
alias virepro='start-nvim-bug-repro'
alias cpath='copy-path-to-clipboard'
alias eme='enter_megascript_environment'

# === UTILITY FUNCTIONS END ===
# === CUSTOM FUNCTIONS END ===

# Initialize final tools
eval "$(zoxide init zsh)"
# eval "$(starship init zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zshexit() {
  if $WSL_ENV; then
    echo "Exiting wsl...👋"
    # Reset Wezterm pane user variable "in_wsl" to false
    printf "\033]1337;SetUserVar=%s=%s\007" in_wsl "MA=="
  fi
}
