#!/usr/bin/env bash

# 1. Use HTTPS instead of SSH for the initial clone. 
# This bypasses the need for SSH keys on a fresh machine.
git clone --bare https://github.com/Dominic-Barber/Dotfiles.git $HOME/.dotfiles

# Define config alias locally since the dotfiles aren't installed yet
function config {
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME "$@"
}

# Create a directory to backup existing dotfiles to
mkdir -p $HOME/.dotfiles-backup

# Attempt checkout
config checkout
if [ $? = 0 ]; then
  echo "Checked out dotfiles from https://github.com/Dominic-Barber/Dotfiles.git"
else
  echo "Moving existing conflicting dotfiles to ~/.dotfiles-backup"
  
  # 2. Use grep -E instead of the deprecated egrep
  # 3. Use a while loop to ensure parent directories exist before moving nested files
  config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
      mkdir -p "$HOME/.dotfiles-backup/$(dirname "$file")"
      mv "$file" "$HOME/.dotfiles-backup/$file"
  done
fi

# Checkout dotfiles from repo
config checkout
config config status.showUntrackedFiles no

# 4. (Optional) Switch the repo back to SSH so you can push changes later
# once you have generated and added your SSH keys to GitHub.
config remote set-url origin git@github.com:Dominic-Barber/Dotfiles.git
