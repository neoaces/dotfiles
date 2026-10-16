#!/usr/bin/env bash
# Claude plan usage (% used), from the cache that ~/.claude/statusline.sh writes
# ("5h_used 5h_reset 7d_used 7d_reset"). Prints a tmux status segment, or a
# starship-style pill with --ansi (used by the Claude Code statusline).
{ read -r fu fr su sr <~/.cache/claude-usage; } 2>/dev/null
[ -n "$sr" ] || exit 0
now=$(date +%s)

# A window that has reset since the cache was written is empty again
((fr <= now)) && fu=0
((sr <= now)) && su=0

reset=""
if ((fr > now && fu > 0)); then
  s=$((fr - now))
  ((s >= 3600)) && reset=" $((s / 3600))h$((s % 3600 / 60))m" || reset=" $((s / 60))m"
fi

# teal normally, amber over 70% used, rose over 90%
high=$((fu > su ? fu : su))
bg="45;212;191" hex="#2dd4bf"
((high > 70)) && bg="251;191;36" hex="#fbbf24"
((high > 90)) && bg="251;113;133" hex="#fb7185"

if [ "$1" = --ansi ]; then
  e=$'\033' l=$'\ue0b6' r=$'\ue0b4'
  printf '%s' "$e[38;2;${bg}m$l$e[48;2;${bg};38;2;12;16;16;1m 󰚩 5h ${fu}%$e[22m${reset} $e[1m· 7d ${su}% $e[0m$e[38;2;${bg}m$r$e[0m"
else
  printf '#[bg=%s,fg=#0c1010,bold] 󰚩 5h %s%%#[nobold]%s #[bold]· 7d %s%% #[default] ' \
    "$hex" "$fu" "$reset" "$su"
fi
