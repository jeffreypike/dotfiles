# 1. Load ble.sh (The Syntax Highlighting Engine)
# Check if it exists and source it
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
    source "$HOME/.local/share/blesh/ble.sh"
fi

# 2. Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# 3. Initialize Starship (The Rainbow Prompt)
# We use a special flag to make sure it plays nice with ble.sh
eval "$(starship init bash)"
