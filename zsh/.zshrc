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

alias acsh="ssh anzlechavez@sdl0-robot-serpens"
alias zrc="source $ZDOTDIR/.zshrc"
alias sink="~/dotfiles.sh"
alias sors="source $ZDOTDIR/.zshrc"
alias czsh="nvim $ZDOTDIR/.zshrc"
alias cdot="nvim ~/dotfiles/config"
alias cvim="nvim ~/dotfiles/config/nvim"
