#!/bin/bash
set -euo pipefail

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
# Always tracks the latest GitHub release so new workspaces can run recent models.
# Post-0.2 releases ship as a tar.zst bundle (binary + CUDA/vulkan libs under lib/ollama).
# Override by exporting OLLAMA_VERSION=vX.Y.Z before running (e.g. to pin in CI).
OLLAMA_VERSION="${OLLAMA_VERSION:-$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest \
    | grep -m1 '"tag_name"' | cut -d'"' -f4)}"

if [ -z "$OLLAMA_VERSION" ]; then
    echo "⚠️  Could not determine latest Ollama version (GitHub API unreachable?). Skipping."
else
    INSTALLED_VERSION=""
    if command -v ollama &> /dev/null; then
        INSTALLED_VERSION="$(ollama --version 2>/dev/null | awk '/version is|client version/ {print $NF; exit}')"
    fi

    if [ "$INSTALLED_VERSION" != "${OLLAMA_VERSION#v}" ]; then
        echo "🦙 Installing Ollama ${OLLAMA_VERSION} (found: ${INSTALLED_VERSION:-none})..."
        TMPDIR="$(mktemp -d)"
        curl -fL "https://github.com/ollama/ollama/releases/download/${OLLAMA_VERSION}/ollama-linux-amd64.tar.zst" \
            -o "$TMPDIR/ollama.tar.zst"
        # zstd ships with recent tar (--zstd); fall back to piping through zstd if not.
        if tar --help 2>&1 | grep -q -- '--zstd'; then
            tar --zstd -xf "$TMPDIR/ollama.tar.zst" -C "$TMPDIR"
        else
            zstd -d -c "$TMPDIR/ollama.tar.zst" | tar -xf - -C "$TMPDIR"
        fi
        rm -f "$HOME/.local/bin/ollama"
        rm -rf "$HOME/.local/lib/ollama"
        mkdir -p "$HOME/.local/lib"
        cp "$TMPDIR/bin/ollama" "$HOME/.local/bin/ollama"
        chmod +x "$HOME/.local/bin/ollama"
        cp -r "$TMPDIR/lib/ollama" "$HOME/.local/lib/ollama"
        rm -rf "$TMPDIR"
        echo "✅ Ollama ${OLLAMA_VERSION} installed."
    else
        echo "✅ Ollama ${OLLAMA_VERSION} is already installed."
    fi
fi

# 3. INSTALL BLE.SH (Syntax Highlighting for Bash)
if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
    echo "🎨 Installing ble.sh (Syntax Highlighting)..."
    mkdir -p "$HOME/.local/share"
    curl -fL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
        | tar xJf - -C "$HOME/.local/share"
    mv "$HOME/.local/share/ble-nightly" "$HOME/.local/share/blesh"
    echo "✅ ble.sh installed."
else
    echo "✅ ble.sh is already installed."
fi

# 4. INSTALL GITHUB CLI (gh)
# Tracks the latest release from github.com/cli/cli. Override with GH_VERSION=vX.Y.Z.
GH_VERSION="${GH_VERSION:-$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
    | grep -m1 '"tag_name"' | cut -d'"' -f4)}"

if [ -z "$GH_VERSION" ]; then
    echo "⚠️  Could not determine latest gh version. Skipping."
else
    INSTALLED_GH=""
    if command -v gh &> /dev/null; then
        INSTALLED_GH="$(gh --version 2>/dev/null | awk 'NR==1 {print $3}')"
    fi
    if [ "$INSTALLED_GH" != "${GH_VERSION#v}" ]; then
        echo "🐙 Installing gh ${GH_VERSION} (found: ${INSTALLED_GH:-none})..."
        TMPDIR="$(mktemp -d)"
        curl -fL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_amd64.tar.gz" \
            | tar xzf - -C "$TMPDIR"
        cp "$TMPDIR/gh_${GH_VERSION#v}_linux_amd64/bin/gh" "$HOME/.local/bin/gh"
        chmod +x "$HOME/.local/bin/gh"
        rm -rf "$TMPDIR"
        echo "✅ gh ${GH_VERSION} installed."
    else
        echo "✅ gh ${GH_VERSION} is already installed."
    fi
fi

# 5. INSTALL thefuck (typo corrector — invoke with `fuck` or `fix` after a failed cmd)
if ! command -v thefuck &> /dev/null; then
    echo "💥 Installing thefuck..."
    if command -v uv &> /dev/null; then
        uv tool install thefuck
    elif command -v pipx &> /dev/null; then
        pipx install thefuck
    elif command -v pip3 &> /dev/null; then
        pip3 install --user thefuck
    else
        echo "⚠️  No uv/pipx/pip3 found — skipping thefuck."
    fi
fi

# 6. LINK FILES
echo "🔗 Linking Configs..."
mkdir -p "$HOME/.config"
ln -sf "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$REPO_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$REPO_DIR/.zshrc" "$HOME/.zshrc"
# .shellrc is sourced by both rcs via $HOME/dotfiles/.shellrc, no symlink needed

# 7. PRE-PULL DEFAULT OLLAMA MODEL (background, non-blocking)
# Skipped if ollama isn't installed, already has the model, or isn't running.
if command -v ollama &> /dev/null; then
    DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-gemma4:e4b}"
    (
        # Give an existing server a moment; if none, start one just for the pull.
        STARTED_BY_INSTALLER=0
        if ! pgrep -u "$USER" -f "ollama serve" >/dev/null 2>&1; then
            nohup ollama serve >"$HOME/.ollama/server.log" 2>&1 &
            STARTED_BY_INSTALLER=1
            sleep 2
        fi
        if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$DEFAULT_MODEL"; then
            echo "📦 Pre-pulling $DEFAULT_MODEL in background..."
            ollama pull "$DEFAULT_MODEL" >/dev/null 2>&1 || true
        fi
        # Only stop ollama if we started it ourselves — leave user sessions alone.
        if [ "$STARTED_BY_INSTALLER" = 1 ]; then
            pkill -u "$USER" -f "ollama serve" >/dev/null 2>&1 || true
        fi
    ) &
    disown 2>/dev/null || true
fi

echo "🎉 Done! Open a new shell or run 'source ~/.bashrc' to load the new config."
