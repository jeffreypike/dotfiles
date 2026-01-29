# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# We leave the theme empty or default because Starship will handle the visuals
ZSH_THEME="robbyrussell"

# Standard plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh My Zsh if it exists
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Add local bin to PATH (for Starship/Ollama)
export PATH="$HOME/.local/bin:$PATH"

# Initialize Starship
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
