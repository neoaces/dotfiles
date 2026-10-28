# Over ssh, use the "SSH" + user@host variant of the main config
if [[ -n $SSH_CONNECTION ]]; then
    mkdir -p ~/.cache
    sed -f ~/.config/starship-ssh.sed ~/.config/starship.toml > ~/.cache/starship-ssh.toml
    export STARSHIP_CONFIG=~/.cache/starship-ssh.toml
fi

# Cached starship init (delete ~/.starship-init.zsh after upgrading starship)
if (( $+commands[starship] )); then
    # -s: an empty cache (written while starship wasn't on PATH) is regenerated
    [[ -s ~/.starship-init.zsh ]] || starship init zsh --print-full-init > ~/.starship-init.zsh
    source ~/.starship-init.zsh
    source ~/.config/starship-fit.sh
fi

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
alias acsh="clear; ssh -t anzlechavez@sdl0-robot-serpens 'tmux new -A -s rr -c ~/Development/chemdroid/real-robot'"
alias acssh="clear; ssh anzlechavez@sdl0-robot-serpens"
alias cdrr="cd ~/Development/chemdroid/real-robot"
alias cdpw="cd ~/Development/chemdroid/real-robot/src/chemdroid_real_robot/powder_weighing"
alias nrr="nvim ~/Development/chemdroid/real-robot"
alias zrc="source $ZDOTDIR/.zshrc"
alias sink="~/.config/dotfiles-sync.sh sync"
alias srs="source $ZDOTDIR/.zshrc"
alias nzsh="nvim $ZDOTDIR/.zshrc"
alias cdot="cd ~/dotfiles"
alias ndot="nvim ~/dotfiles"
alias cdvim="cd ~/dotfiles/nvim"
alias nnvim="nvim ~/dotfiles/nvim"
alias psst="pbpaste"
alias nv="nvim ."
alias aider-oss="/home/neoaces/Development/ai/aider.sh"   # aider + local gpt-oss:20b via Ollama
google() {
  local query="${*// /+}"
  open "https://www.google.com/search?q=${query}"
}

# Old dotfiles layout (repo at ~/dotfiles/config) — `sink` migrates it to ~/dotfiles
[ -d "$HOME/dotfiles/config/.git" ] && echo "dotfiles: old ~/dotfiles/config layout detected — run 'sink' to migrate to ~/dotfiles"

# Completion (dump kept out of the synced folder)
autoload -Uz compinit && compinit -d ~/.cache/zcompdump

# Powder colours for the line editor, completion, ls/grep and plugins — keep last
source $ZDOTDIR/powder.zsh
