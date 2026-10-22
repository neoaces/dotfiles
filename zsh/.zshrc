# Over ssh, use the "SSH" + user@host variant of the main config
if [[ -n $SSH_CONNECTION ]]; then
    mkdir -p ~/.cache
    sed -f ~/.config/starship-ssh.sed ~/.config/starship.toml > ~/.cache/starship-ssh.toml
    export STARSHIP_CONFIG=~/.cache/starship-ssh.toml
fi

# Cached starship init (delete ~/.starship-init.zsh after upgrading starship)
[[ -f ~/.starship-init.zsh ]] || starship init zsh --print-full-init > ~/.starship-init.zsh
source ~/.starship-init.zsh

# conda: lazy-loaded on first use (eager `conda init` cost ~0.8s per shell)
conda() {
    unfunction conda
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
    unset __conda_setup
    conda "$@"
}

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
alias acsh="ssh anzlechavez@sdl0-robot-serpens; clear"
alias cdrr="cd ~/Development/chemdroid/real-robot"
alias nrr="nvim ~/Development/chemdroid/real-robot"
alias zrc="source $ZDOTDIR/.zshrc"
alias sink="~/.config/dotfiles-sync.sh sync"
alias srs="source $ZDOTDIR/.zshrc"
alias nzsh="nvim $ZDOTDIR/.zshrc"
alias cdot="cd ~/dotfiles/config"
alias ndot="nvim ~/dotfiles/config"
alias cdvim="cd ~/dotfiles/config/nvim"
alias nnvim="nvim ~/dotfiles/config/nvim"
alias psst="pbpaste"
alias nv="nvim ."
alias aider-oss="/home/neoaces/Development/ai/aider.sh"   # aider + local gpt-oss:20b via Ollama
google() {
  local query="${*// /+}"
  open "https://www.google.com/search?q=${query}"
}
