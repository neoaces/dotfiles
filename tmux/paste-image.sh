#!/usr/bin/env bash
# Paste clipboard image into the active tmux pane. If the pane is running ssh,
# copy the image to the remote host and type the remote path instead.
# usage: paste-image.sh <pane_pid>
pane_pid=$1
name=clip-$(date +%s).png
f=/tmp/$name

if ! xclip -selection clipboard -t image/png -o > "$f" 2>/dev/null || [ ! -s "$f" ]; then
  rm -f "$f"
  tmux send-keys -l -- "$(xclip -selection clipboard -o)"
  exit
fi

# Find an ssh process under the pane; its last argument is the host
host=$(pgrep -P "$pane_pid" -a -x ssh | head -n1 | awk '{print $NF}')

if [ -n "$host" ] && scp -q "$f" "$host:/tmp/$name" 2>/dev/null; then
  tmux send-keys -l -- "/tmp/$name "
else
  [ -n "$host" ] && tmux display-message "scp to $host failed"
  tmux send-keys -l -- "$f "
fi
