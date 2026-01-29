#!/bin/bash

# 1. Install Starship (if missing)
if ! command -v starship &> /dev/null; then
    echo "🚀 Installing Starship..."
    mkdir -p "$HOME/.local/bin"
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
fi

# 2. Link Configs
# This assumes the script is run from inside the repo
REPO_DIR="$PWD"

# Helper function to backup and link
link_file() {
    local src="$1"
    local dest="$2"

    # Backup if it exists and is not already a symlink
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.backup"
    fi
    
    # Create the link
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
}

# Link Starship Config
link_file "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Link Bash Config (For Coder Remote)
link_file "$REPO_DIR/.bashrc" "$HOME/.bashrc"

# Link Zsh Config (For Local Mac / Future Zsh use)
link_file "$REPO_DIR/.zshrc" "$HOME/.zshrc"

echo "✅ Dotfiles installed! Please restart your terminal."
