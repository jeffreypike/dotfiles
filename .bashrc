# Load system defaults if they exist
[ -f /etc/bashrc ] && . /etc/bashrc

# Add ~/.local/bin to PATH so it finds Starship
export PATH="$HOME/.local/bin:$PATH"

# Start Starship
eval "$(starship init bash)"
