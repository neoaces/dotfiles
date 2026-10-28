# Powder — zsh port of the Ghostty theme (ghostty/themes/Powder): zinc text,
# cobalt for selection and focus, lime for commands that resolve. Colours
# follow nvim/colors/powder.lua. Sourced last by .zshrc (syntax highlighting
# must load after every other widget).

# Without truecolor (some ssh/tmux setups) map the hex colours to the nearest of 256
[[ $COLORTERM == *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

typeset -gA powder=(
    bg       '#0c1010'
    surface  '#1a1b21'
    muted    '#5d6070'
    text     '#b6bac8'
    fg       '#cfd3dd'
    bright   '#dde1ea'
    selection '#1a302d'
    cobalt   '#0047ab'
    red      '#fb7185'
    lime     '#a3e635'
    lime_br  '#bef264'
    yellow   '#fbbf24'
    blue     '#6b97f2'
    blue_br  '#9dbbf7'
    magenta  '#a78bfa'
    cyan_br  '#5eead4'
)

# --- Line editor -------------------------------------------------------------
zle_highlight=(
    "region:bg=$powder[selection]"
    "isearch:fg=$powder[bright],bg=$powder[cobalt],bold"
    "special:fg=$powder[cyan_br]"
    "suffix:fg=$powder[muted]"
    "paste:none"
)

# --- ls / grep ---------------------------------------------------------------
# ANSI slots, so they follow the terminal's Powder palette: dirs blue, links
# cyan, executables lime, sockets/pipes magenta/yellow
export CLICOLOR=1
export LSCOLORS='exgxfxdxcxegedabagacad'
export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
export GREP_COLORS='mt=1;32' GREP_COLOR='1;32'
alias grep='grep --color=auto'
[[ $OSTYPE == linux* ]] && alias ls='ls --color=auto'

# --- Completion menu (file colours from LS_COLORS above) ---------------------
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format "%F{$powder[lime]}%B%d%b%f"
zstyle ':completion:*:messages' format "%F{$powder[blue]}%d%f"
zstyle ':completion:*:warnings' format "%F{$powder[red]}no matches%f"
zstyle ':completion:*:corrections' format "%F{$powder[yellow]}%d (errors: %e)%f"
# Selected entry: the cobalt block the starship prompt and tmux bar use
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} 'ma=1;38;2;221;225;234;48;2;0;71;171'

# --- Plugins (installed by `dotfiles-sync.sh deps`) --------------------------
_powder_plugins=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins

if [[ -r $_powder_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$powder[muted]"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    source $_powder_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r $_powder_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source $_powder_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
    typeset -gA ZSH_HIGHLIGHT_STYLES
    # Commands that resolve are lime; anything that doesn't is rose
    ZSH_HIGHLIGHT_STYLES[command]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=$powder[lime],underline"
    ZSH_HIGHLIGHT_STYLES[global-alias]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[function]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[precommand]="fg=$powder[lime],italic"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=$powder[red]"
    ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=$powder[magenta]"
    ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=$powder[cyan_br]"
    ZSH_HIGHLIGHT_STYLES[redirection]="fg=$powder[cyan_br]"
    ZSH_HIGHLIGHT_STYLES[globbing]="fg=$powder[cyan_br]"
    ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=$powder[cyan_br]"
    # Flags in the cobalt family, paths in its lighter tint
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=$powder[blue]"
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=$powder[blue]"
    ZSH_HIGHLIGHT_STYLES[path]="fg=$powder[blue_br],underline"
    ZSH_HIGHLIGHT_STYLES[path_prefix]="fg=$powder[blue_br]"
    ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=$powder[blue_br],underline"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=$powder[lime_br]"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=$powder[lime_br]"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=$powder[lime_br]"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=$powder[cyan_br]"
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=$powder[yellow]"
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg=$powder[yellow]"
    ZSH_HIGHLIGHT_STYLES[assign]="fg=$powder[yellow]"
    ZSH_HIGHLIGHT_STYLES[comment]="fg=$powder[muted],italic"
    ZSH_HIGHLIGHT_STYLES[default]="fg=$powder[fg]"
    ZSH_HIGHLIGHT_STYLES[arg0]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=$powder[red],bold"
    ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=$powder[blue]"
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=$powder[lime]"
    ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=$powder[magenta]"
    ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=$powder[bright],bg=$powder[cobalt]"
fi

unset _powder_plugins
