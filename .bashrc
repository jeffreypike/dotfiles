# 1. PATH (Do this FIRST so binaries like 'starship' and 'ollama' are found)
export PATH="$HOME/.local/bin:$PATH"

# 2. Starship (Initialize the prompt)
# We check if starship exists first to avoid errors
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# 3. Ble.sh (Syntax Highlighting - MUST BE LAST)
# It wraps the prompt, so it needs to run after Starship
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
    source "$HOME/.local/share/blesh/ble.sh"
fi
