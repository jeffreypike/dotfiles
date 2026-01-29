#!/bin/bash

REPO_DIR="$HOME/dotfiles"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

echo "🔧 Starting Setup..."

# 1. INSTALL STARSHIP
if ! command -v starship &> /dev/null; then
    echo "🚀 Installing Starship..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
fi

# 2. INSTALL OLLAMA
if ! command -v ollama &> /dev/null; then
    echo "🦙 Installing Ollama..."
    # We use a specific version (v0.1.32) because we verified it works on your network.
    curl -L https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64 -o "$HOME/.local/bin/ollama"
    chmod +x "$HOME/.local/bin/ollama"
    echo "✅ Ollama installed."
else
    echo "✅ Ollama is already installed."
fi

# 3. INSTALL BLE.SH (Syntax Highlighting for Bash)
if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
    echo "🎨 Installing ble.sh (Syntax Highlighting)..."
    mkdir -p "$HOME/.local/share"
    # Download the nightly build (pre-compiled)
    curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$HOME/.local/share"
    # Rename folder to standard name
    mv "$HOME/.local/share/ble-nightly" "$HOME/.local/share/blesh"
    echo "✅ ble.sh installed."
else
    echo "✅ ble.sh is already installed."
fi

# 4. LINK FILES
echo "🔗 Linking Configs..."
# Clean up old links
rm -rf "$HOME/.config/starship.toml" "$HOME/.bashrc" "$HOME/.zshrc"

# Link Starship
mkdir -p "$HOME/.config"
ln -s "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Link Bashrc
ln -s "$REPO_DIR/.bashrc" "$HOME/.bashrc"

# Link Zshrc (Just in case you use it locally)
ln -s "$REPO_DIR/.zshrc" "$HOME/.zshrc"

echo "🎉 Done! Type 'source ~/.bashrc' to load the highlighting!"
