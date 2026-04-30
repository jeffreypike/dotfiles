# Oh My Zsh (local mac only — skipped silently if not installed)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # Starship handles the prompt
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Shared config (PATH, starship, thefuck, ollama helpers, ...)
if [ -f "$HOME/dotfiles/.shellrc" ]; then
    source "$HOME/dotfiles/.shellrc"
fi
