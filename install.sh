#!/bin/bash

# 1. Install Starship (if missing)
if ! command -v starship &> /dev/null; then
    echo "🚀 Installing Starship..."
    mkdir -p "$HOME/.local/bin"
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
fi

# 2. Function to backup and link files
link_file() {
    local src="$1"
    local dest="$2"

    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # If the file exists and is NOT a symlink, back it up
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "📦 Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    # Create the symlink
    # -s = symbolic, -f = force (overwrite if exists), -n = no dereference
    echo "🔗 Linking $dest -> $src"
    ln -sfn "$src" "$dest"
}

# 3. Create the links
# These variables assume the script is run from inside the dotfiles folder
REPO_DIR="$PWD"

# Link Starship Config
link_file "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Link Shell Configs
link_file "$REPO_DIR/.bashrc" "$HOME/.bashrc"
link_file "$REPO_DIR/.zshrc" "$HOME/.zshrc"

echo "✅ Dotfiles installed! Restart your terminal."