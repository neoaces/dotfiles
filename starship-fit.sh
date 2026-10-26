# Narrow panes: the prompt sheds the user, then the host's prefix, then the
# host and the path's parents, so its first line never wraps.
# Sourced by .bashrc and .zshrc after `starship init`.

_starship_fit_dir=$HOME/.cache/starship-fit
mkdir -p "$_starship_fit_dir"
# A re-sourced rc or a nested shell inherits the variant last picked
case ${STARSHIP_CONFIG-} in
    "$_starship_fit_dir"/*) unset STARSHIP_CONFIG ;;
esac
_starship_fit_host=${HOSTNAME:-$HOST}
_starship_fit_host=${_starship_fit_host%%.*}

# 0: as configured; 1: host only; 2: the host's last "-" part; 3: no host, folder only
cp "${STARSHIP_CONFIG:-$HOME/.config/starship.toml}" "$_starship_fit_dir/0.toml"
sed -e '/^\[\](fg:bright-black)\\$/d' -e '/^\$username\\$/d' \
    -e 's/^\[\](fg:green bg:bright-black)/[](fg:green)/' \
    -e 's/^\$username\$hostname\\$/$hostname\\/' \
    -e 's/^format = "\[@\$hostname \]/format = "[ $hostname ]/' \
    "$_starship_fit_dir/0.toml" >"$_starship_fit_dir/1.toml"
sed -e "s/^format = \"\[ \\\$hostname \]/format = \"[ ${_starship_fit_host##*-} ]/" \
    "$_starship_fit_dir/1.toml" >"$_starship_fit_dir/2.toml"
sed -e '/^\$hostname\\$/d' -e 's/^truncation_length = .*/truncation_length = 1/' \
    "$_starship_fit_dir/2.toml" >"$_starship_fit_dir/3.toml"

_starship_fit() {
    local level=0 line duration=${STARSHIP_DURATION-}
    # bash's starship_precmd works out the duration only after this hook
    if [ -n "${BASH_VERSION-}" ] && [ -n "${STARSHIP_START_TIME-}" ]; then
        duration=$(( $(starship time) - STARSHIP_START_TIME ))
    fi
    while [ "$level" -lt 3 ]; do
        # At width 1 the fill is at its minimum, so this is the line's least width
        line=$(STARSHIP_CONFIG=$_starship_fit_dir/$level.toml STARSHIP_SHELL= \
            starship prompt --terminal-width=1 --status="${STARSHIP_CMD_STATUS-0}" \
            --cmd-duration="$duration" | sed -n $'/./{s/\e\\[[0-9;]*m//g;p;q;}')
        [ "${#line}" -le "${COLUMNS:-80}" ] && break
        level=$((level + 1))
    done
    export STARSHIP_CONFIG=$_starship_fit_dir/$level.toml
}

if [ -n "${ZSH_VERSION-}" ]; then
    precmd_functions=(${precmd_functions:#_starship_fit} _starship_fit)
else
    starship_precmd_user_func=_starship_fit
fi
