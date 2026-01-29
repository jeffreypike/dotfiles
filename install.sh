cat << 'EOF' > install.sh
#!/bin/bash

# =============================================================================
#  CONFIG & PATHS
# =============================================================================

# Force the script to assume the repo is located at ~/dotfiles
# This prevents relative path errors when running the script from other folders.
REPO_DIR="$HOME/dotfiles"

# Ensure ~/.local/bin exists and is in PATH for this session
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

echo "🔧 Starting Dotfiles Installation..."

# =============================================================================
#  1. INSTALL STARSHIP (Visuals)
# =============================================================================

if ! command -v starship &> /dev/null; then
    echo "🚀 Installing Starship..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
else
    echo "✅ Starship is already installed."
fi

# =============================================================================
#  2. INSTALL OLLAMA (AI)
# =============================================================================

if ! command -v ollama &> /dev/null; then
    echo "🦙 Installing Ollama (User-space)..."
    # Download Linux AMD64 binary
    curl -L https://ollama.com/download/ollama-linux-amd64 -o "$HOME/.local/bin/ollama"
    chmod +x "$HOME/.local/bin/ollama"
    echo "✅ Ollama installed."
else
    echo "✅ Ollama is already installed."
fi

# =============================================================================
#  3. LINK CONFIG FILES
# =============================================================================

echo "🔗 Linking Configuration Files..."

# Helper function to link files safely
link_file() {
    local source_file="$1"
    local target_file="$2"

    # Check if source exists in the repo
    if [ ! -e "$source_file" ]; then
        echo "⚠️  WARNING: Source file not found: $source_file"
        return
    fi

    # Create target directory if needed
    mkdir -p "$(dirname "$target_file")"

    # Remove existing file or symlink to avoid loops/errors
    rm -rf "$target_file"

    # Create the symlink
    ln -s "$source_file" "$target_file"
    echo "   Linked: $target_file -> $source_file"
}

# Link Starship Config
link_file "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Link Shell Configs
link_file "$REPO_DIR/.bashrc" "$HOME/.bashrc"
link_file "$REPO_DIR/.zshrc" "$HOME/.zshrc"

# =============================================================================
#  4. FINISH
# =============================================================================

echo "🎉 Setup Complete!"
echo "👉 Type 'source ~/.bashrc' (or restart your terminal) to see the changes."
EOF
