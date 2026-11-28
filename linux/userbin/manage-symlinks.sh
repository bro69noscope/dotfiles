#!/bin/bash

# Dotfiles symlink setup script
# This script checks if dotfile symlinks exist and creates them if they don't

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

# Function to create symlink with directory creation
create_symlink() {
  local target="$1"
  local link="$2"
  local link_dir=$(dirname "$link")

  # Create directory if it doesn't exist
  if [ ! -d "$link_dir" ]; then
    echo -e "${BLUE}Creating directory: $link_dir${NC}"
    mkdir -p "$link_dir"
  fi

  # Create the symlink
  if ln -sf "$target" "$link"; then
    echo -e "${GREEN}✓ Created: $link -> $target${NC}"
    return 0
  else
    echo -e "${RED}✗ Failed to create: $link -> $target${NC}"
    return 1
  fi
}

# Function to check and create symlink
check_and_create() {
  local target="$1"
  local link="$2"

  # Check if target exists
  if [ ! -e "$target" ]; then
    echo -e "${RED}✗ Target doesn't exist: $target${NC}"
    return 1
  fi

  # Check if symlink already exists and points to correct target
  if [ -L "$link" ]; then
    current_target=$(readlink "$link")
    if [ "$current_target" = "$target" ]; then
      echo -e "${GREEN}✓ Already exists: $link -> $target${NC}"
      return 0
    else
      echo -e "${YELLOW}! Updating symlink: $link${NC}"
      echo -e "  Old target: $current_target"
      echo -e "  New target: $target"
      create_symlink "$target" "$link"
    fi
  elif [ -e "$link" ]; then
    echo -e "${YELLOW}! File exists but is not a symlink: $link${NC}"
    read -p "Backup and replace with symlink? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      mv "$link" "${link}.backup"
      echo -e "${BLUE}Backed up to: ${link}.backup${NC}"
      create_symlink "$target" "$link"
    fi
  else
    echo -e "${BLUE}Creating new symlink: $link${NC}"
    create_symlink "$target" "$link"
  fi
}

echo -e "${BLUE}Dotfiles Symlink Setup${NC}"
echo "=============================="

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
  echo -e "${RED}Error: Dotfiles directory not found: $DOTFILES_DIR${NC}"
  exit 1
fi

echo -e "${BLUE}Using dotfiles directory: $DOTFILES_DIR${NC}"
echo

# Define all the symlinks (target -> link)
declare -A SYMLINKS=(
  # Shell configs
  ["$DOTFILES_DIR/linux/.zshrc"]="$HOME/.zshrc"
  ["$DOTFILES_DIR/linux/.bashrc"]="$HOME/.bashrc"
  ["$DOTFILES_DIR/linux/.p10k.zsh"]="$HOME/.p10k.zsh"
  ["$DOTFILES_DIR/linux/.tmux.conf"]="$HOME/.tmux.conf"

  # Git config
  ["$DOTFILES_DIR/.gitconfig"]="$HOME/.gitconfig"

  # Application configs
  ["$DOTFILES_DIR/lazygit/lazygit-config.yml"]="$HOME/.config/lazygit/config.yml"
  ["$DOTFILES_DIR/linux/sship_custom_mnt_path_module.toml"]="$HOME/.config/sship_custom_mnt_path_module.toml"
  ["$DOTFILES_DIR/nvim-config3.0"]="$HOME/.config/nvim"
  ["$DOTFILES_DIR/starship/starship.toml"]="$HOME/.config/starship.toml"

  # User binaries
  ["$DOTFILES_DIR/linux/userbin/wsl-ssh-agent-relay.sh"]="$HOME/bin/wsl-ssh-agent-relay.sh"
  ["$DOTFILES_DIR/linux/userbin/sync-next-level-live-streaming.sh"]="$HOME/bin/sync-next-level-live-streaming.sh"

  # Yazi config
  ["$DOTFILES_DIR/yazi-config/keymap.toml"]="$HOME/.config/yazi/keymap.toml"
  ["$DOTFILES_DIR/yazi-config/package.toml"]="$HOME/.config/yazi/package.toml"
  ["$DOTFILES_DIR/yazi-config/theme.toml"]="$HOME/.config/yazi/theme.toml"
  ["$DOTFILES_DIR/yazi-config/yazi.toml"]="$HOME/.config/yazi/yazi.toml"
)

# Process each symlink
for target in "${!SYMLINKS[@]}"; do
  link="${SYMLINKS[$target]}"
  check_and_create "$target" "$link"
done

echo
echo -e "${BLUE}Setup complete!${NC}"
