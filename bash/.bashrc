# Synced bashrc (~/.config/bash/.bashrc). ~/.bashrc just sources this file.
# Kept in step with ~/.config/zsh/.zshrc — same aliases, bash syntax.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

BASHRC_FILE="${BASH_SOURCE[0]}"

# --- Stock Ubuntu defaults ---------------------------------------------------
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- Prompt ------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='\u@\h:\w\$ '
fi

# --- conda: lazy-loaded on first use (same idea as the zshrc) -----------------
for __conda_base in /opt/homebrew/Caskroom/miniconda/base "$HOME/miniconda3" "$HOME/anaconda3" /opt/conda; do
    if [ -x "$__conda_base/bin/conda" ]; then
        CONDA_BASE="$__conda_base"
        conda() {
            unset -f conda
            __conda_setup="$("$CONDA_BASE/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            elif [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
                . "$CONDA_BASE/etc/profile.d/conda.sh"
            else
                export PATH="$CONDA_BASE/bin:$PATH"
            fi
            unset __conda_setup
            conda "$@"
        }
        break
    fi
done
unset __conda_base

# --- PATH --------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# --- Aliases (mirrors zshrc) -------------------------------------------------
alias acsh="ssh anzlechavez@sdl0-robot-serpens"
alias cdrr="cd ~/Development/chemdroid/real-robot"
alias zrc="source $BASHRC_FILE"         # in bash, reloads this bashrc
alias srs="source $BASHRC_FILE"
alias brc="source $BASHRC_FILE"
alias czsh="nvim ~/.config/zsh/.zshrc"
alias cbash="nvim $BASHRC_FILE"
alias sink="~/.config/dotfiles-sync.sh sync"
alias cdot="nvim ~/dotfiles/config"
alias cvim="nvim ~/dotfiles/config/nvim"
alias nv="nvim ."
alias aider-oss="/home/neoaces/Development/ai/aider.sh"   # aider + local gpt-oss:20b via Ollama

# pbpaste / open are macOS-only; fall back to Linux equivalents
if command -v pbpaste >/dev/null 2>&1; then
    alias psst="pbpaste"
elif command -v wl-paste >/dev/null 2>&1; then
    alias psst="wl-paste"
else
    alias psst="xclip -selection clipboard -o"
fi

google() {
    local query="${*// /+}"
    if command -v open >/dev/null 2>&1 && [[ "$OSTYPE" == darwin* ]]; then
        open "https://www.google.com/search?q=${query}"
    else
        xdg-open "https://www.google.com/search?q=${query}" >/dev/null 2>&1
    fi
}
