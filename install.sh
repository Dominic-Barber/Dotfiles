#!/usr/bin/env bash

# --- Existing Dotfiles Setup ---
git clone --bare git@github.com:Dominic-Barber/Dotfiles.git $HOME/.dotfiles

# define config alias locally since the dotfiles
# aren't installed on the system yet
function config {
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}

# create a directory to backup existing dotfiles to
mkdir -p .dotfiles-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out dotfiles from git@github.com:Dominic-Barber/Dotfiles.git";
else
  echo "Moving existing dotfiles to ~/.dotfiles-backup";
  config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi

# checkout dotfiles from repo
config checkout
config config status.showUntrackedFiles no

# --- Arch Linux Software Installation Prompt ---
echo ""
read -p "Would you like to install your essential programs for Arch Linux? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Arch Linux software installation..."
    
    # 1. Ensure system is up to date
    sudo pacman -Syu --noconfirm

    # 2. Bootstrap AUR helper (yay) if not installed
    if ! command -v yay &> /dev/null; then
        echo "Installing yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        (cd /tmp/yay-bin && makepkg -si --noconfirm)
        rm -rf /tmp/yay-bin
    fi

    # 3. Install Official Repository Packages
    # Note: Steam requires the [multilib] repository to be enabled.
    echo "Installing official packages..."
    sudo pacman -S --needed --noconfirm neovim bitwarden steam

    # 4. Install AUR Packages
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm \
        firefox-nightly-bin \
        visual-studio-code-bin \
        spotify \
        minecraft-launcher \
        curseforge \
        vicinae
    
    echo ""
    echo "Software installation complete!"
    echo "Note: If Steam failed to install, ensure you have uncommented [multilib] in /etc/pacman.conf."
else
    echo "Skipping software installation."
fi
