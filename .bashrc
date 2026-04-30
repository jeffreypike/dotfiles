# Shared config (PATH, starship, thefuck, ollama helpers, ...)
if [ -f "$HOME/dotfiles/.shellrc" ]; then
    . "$HOME/dotfiles/.shellrc"
fi

# ble.sh (bash-only syntax highlighting) — MUST be last, wraps the prompt.
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
    source "$HOME/.local/share/blesh/ble.sh"
fi
