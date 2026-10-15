#!/usr/bin/env bash
# macOS side: whenever a new image lands on the Mac clipboard, push it into the
# remote Ubuntu box's X clipboard. Then Ctrl+V in Claude Code (in tmux over ssh)
# pastes it, no extra step. Run via launchd (see mac-clipboard-sync.plist).
# Needs: brew install pngpaste; key-based ssh to $REMOTE.
REMOTE=${REMOTE:-anzlechavez@sdl0-robot-serpens}
R_ENV='DISPLAY=:1 XAUTHORITY=/run/user/1002/gdm/Xauthority'

tmp=$(mktemp -t clipsync)
trap 'rm -f "$tmp"' EXIT
last=

while sleep 1; do
  pngpaste "$tmp" 2>/dev/null || { last=; continue; }
  sum=$(md5 -q "$tmp")
  [ "$sum" = "$last" ] && continue
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE" \
      "$R_ENV xclip -selection clipboard -t image/png -i" < "$tmp" >/dev/null 2>&1; then
    last=$sum
  fi
done
