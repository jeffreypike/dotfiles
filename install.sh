#!/bin/bash
set -euo pipefail

REPO_DIR="$HOME/dotfiles"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Use ~/.cache for large downloads — /tmp is often tiny or memory-backed
CACHE_DIR="$HOME/.cache/dotfiles-install"
mkdir -p "$CACHE_DIR"

echo "🔧 Starting Setup..."

# 0. INSTALL mawk (BusyBox awk on Chainguard mangles backslash escapes in gsub,
# which breaks ble.sh's bind-save quoting and produces noisy
#   `bash: eval: line N: syntax error near unexpected token \`(\''`
# warnings on every shell startup. mawk builds in seconds and ble.sh prefers it
# automatically over busybox awk.)
if ! command -v mawk &> /dev/null && ! command -v gawk &> /dev/null && ! command -v nawk &> /dev/null; then
    echo "🦖 Installing mawk (workaround for busybox awk gsub bug)..."
    MAWK_DIR="$CACHE_DIR/mawk-src"
    rm -rf "$MAWK_DIR" && mkdir -p "$MAWK_DIR"
    if curl -fsSL https://invisible-island.net/archives/mawk/mawk.tar.gz \
        | tar xzf - -C "$MAWK_DIR" --strip-components=1 \
        && (cd "$MAWK_DIR" && ./configure --prefix="$HOME/.local" >/dev/null 2>&1 && make -s >/dev/null 2>&1); then
        cp "$MAWK_DIR/mawk" "$HOME/.local/bin/mawk"
        chmod +x "$HOME/.local/bin/mawk"
        echo "✅ mawk installed."
    else
        echo "⚠️  mawk build failed; ble.sh may emit syntax-error warnings."
    fi
    rm -rf "$MAWK_DIR"
fi

# 1. INSTALL STARSHIP
if ! command -v starship &> /dev/null; then
    echo "🚀 Installing Starship..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
fi

# 2. INSTALL OLLAMA
# Always tracks the latest GitHub release so new workspaces can run recent models.
# Post-0.2 releases ship as a tar.zst bundle (binary + CUDA/vulkan libs under lib/ollama).
# Override by exporting OLLAMA_VERSION=vX.Y.Z before running (e.g. to pin in CI).
if [ -z "${OLLAMA_VERSION:-}" ]; then
    echo "🦙 Fetching latest ollama version..."
    OLLAMA_VERSION="$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest 2>/dev/null \
        | grep -m1 '"tag_name"' | cut -d'"' -f4 || true)"
    # Fallback to a known-good version if the API call fails
    if [ -z "$OLLAMA_VERSION" ]; then
        echo "⚠️  GitHub API unreachable; falling back to ollama v0.22.0"
        OLLAMA_VERSION="v0.22.0"
    fi
fi

if [ -n "$OLLAMA_VERSION" ]; then
    INSTALLED_VERSION=""
    if command -v ollama &> /dev/null; then
        INSTALLED_VERSION="$(ollama --version 2>/dev/null | awk '/version is|client version/ {print $NF; exit}')"
    fi

    if [ "$INSTALLED_VERSION" != "${OLLAMA_VERSION#v}" ]; then
        echo "🦙 Installing Ollama ${OLLAMA_VERSION} (found: ${INSTALLED_VERSION:-none})..."
        WORK_DIR="$CACHE_DIR/ollama-${OLLAMA_VERSION}"
        mkdir -p "$WORK_DIR"
        # Stream decompression (curl | zstd | tar) to avoid writing 2GB tarball to disk.
        # Only the final extracted files land on disk, cutting space usage in half.
        curl -fL "https://github.com/ollama/ollama/releases/download/${OLLAMA_VERSION}/ollama-linux-amd64.tar.zst" \
            | zstd -d -c | tar -xf - -C "$WORK_DIR"
        rm -f "$HOME/.local/bin/ollama"
        rm -rf "$HOME/.local/lib/ollama"
        mkdir -p "$HOME/.local/lib"
        cp "$WORK_DIR/bin/ollama" "$HOME/.local/bin/ollama"
        chmod +x "$HOME/.local/bin/ollama"
        cp -r "$WORK_DIR/lib/ollama" "$HOME/.local/lib/ollama"
        rm -rf "$WORK_DIR"
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
if [ -z "${GH_VERSION:-}" ]; then
    echo "🐙 Fetching latest gh version..."
    GH_VERSION="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null \
        | grep -m1 '"tag_name"' | cut -d'"' -f4 || true)"
    # Fallback to a known-good version if the API call fails
    if [ -z "$GH_VERSION" ]; then
        echo "⚠️  GitHub API unreachable; falling back to gh v2.92.0"
        GH_VERSION="v2.92.0"
    fi
fi

if [ -n "$GH_VERSION" ]; then
    INSTALLED_GH=""
    if command -v gh &> /dev/null; then
        INSTALLED_GH="$(gh --version 2>/dev/null | awk 'NR==1 {print $3}')"
    fi
    if [ "$INSTALLED_GH" != "${GH_VERSION#v}" ]; then
        echo "🐙 Installing gh ${GH_VERSION} (found: ${INSTALLED_GH:-none})..."
        WORK_DIR="$CACHE_DIR/gh-${GH_VERSION}"
        mkdir -p "$WORK_DIR"
        curl -fL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_amd64.tar.gz" \
            | tar xzf - -C "$WORK_DIR"
        cp "$WORK_DIR/gh_${GH_VERSION#v}_linux_amd64/bin/gh" "$HOME/.local/bin/gh"
        chmod +x "$HOME/.local/bin/gh"
        rm -rf "$WORK_DIR"
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
            mkdir -p "$HOME/.ollama"
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
