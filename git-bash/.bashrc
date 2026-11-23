# PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export DOTFILES="$HOME/myfiles/dotfiles/"

# history
HISTSIZE=5000
HISTFILESIZE=5000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# pickers
export FZF_DEFAULT_OPTS='--layout=reverse --height=40% --preview-window=hidden'
eval "$(fzf --bash)"         # ^r history, ^t files, alt-c dirs, **<Tab>
eval "$(zoxide init bash)"   # z, zi
eval "$(starship init bash)" # replaces p10k

# aliases
alias vi='nvim'
alias l='eza --icons -l'
alias la='eza --icons -la'
alias d='la'
alias lt='eza --icons -T'
alias lat='eza --icons -laT'
alias zz='z -'
alias wh='type -a'
alias dot='cd $DOTFILES'
alias vid='cd ~/.config/nvim'
alias gitcfg='git config --global -e'
alias zshcfg='nvim ~/.bashrc'

# copy path (xclip -> clip)
cpath() {
  local p
  p=$(realpath "$1" 2>/dev/null) || {
    echo "Error: not found"
    return 1
  }
  printf '%s' "$(cygpath -w "$p")" | clip
  echo "Copied to clipboard: $p"
}

# yazi needs file.exe, and Windows-style paths for the cwd file
export YAZI_FILE_ONE="$(cygpath -w "$(command -v file)")"
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
  yazi "$@" --cwd-file="$(cygpath -w "$tmp")"
  cwd="$(tr -d '\r' <"$tmp")"
  if [ -n "$cwd" ] && [ "$(cygpath -u "$cwd")" != "$PWD" ]; then
    builtin cd -- "$(cygpath -u "$cwd")" && zoxide add "$PWD"
  fi
  rm -f -- "$tmp"
}
