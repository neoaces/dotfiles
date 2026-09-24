#!/usr/bin/env bash
#
# dotfiles-sync.sh — manage and sync your entire ~/.config directory between
# machines via git. ~/.config becomes a symlink to a git repo; this script
# wraps the day-to-day git commands.
#
# Usage:
#   ./dotfiles-sync.sh init <git-remote-url>    First-time setup on a machine
#                                                 (clones the repo + creates the symlink)
#   ./dotfiles-sync.sh link                      (Re)create the ~/.config symlink
#   ./dotfiles-sync.sh pull                      Pull remote changes only
#   ./dotfiles-sync.sh push ["commit message"]   Commit + push local changes only
#   ./dotfiles-sync.sh sync ["commit message"]   Pull, then commit + push — the everyday command
#   ./dotfiles-sync.sh status                    Show repo + symlink status
#
# Config (override via env vars if you want a different layout):
#   DOTFILES_DIR   Where the git repo lives locally   (default: ~/dotfiles/config)
#   CONFIG_DIR     Where apps expect their configs      (default: ~/.config)

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles/config}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config}"

c_green()  { printf '\033[32m%s\033[0m\n' "$1"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
c_red()    { printf '\033[31m%s\033[0m\n' "$1"; }

current_branch() {
  git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD
}

cmd_link() {
  if [[ -L "$CONFIG_DIR" ]]; then
    c_yellow "Symlink already in place: $CONFIG_DIR -> $(readlink "$CONFIG_DIR")"
    return
  fi

  if [[ -e "$CONFIG_DIR" ]]; then
    local backup="${CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$CONFIG_DIR" "$backup"
    c_yellow "Existing $CONFIG_DIR backed up to $backup"
  fi

  mkdir -p "$(dirname "$CONFIG_DIR")"
  ln -s "$DOTFILES_DIR" "$CONFIG_DIR"
  c_green "Linked $CONFIG_DIR -> $DOTFILES_DIR"
}

cmd_init() {
  local remote="${1:-}"
  if [[ -z "$remote" ]]; then
    c_red "Usage: $0 init <git-remote-url>"
    exit 1
  fi

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    c_yellow "Repo already exists at $DOTFILES_DIR — skipping clone."
  else
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$remote" "$DOTFILES_DIR"
  fi

  cmd_link
  c_green "Init complete."
}

cmd_pull() {
  git -C "$DOTFILES_DIR" pull --rebase --autostash origin "$(current_branch)"
}

cmd_push() {
  local msg="${1:-update: $(date '+%Y-%m-%d %H:%M')}"
  (
    cd "$DOTFILES_DIR"
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "$msg"
    else
      c_yellow "No local changes to commit."
    fi
    git push origin "$(current_branch)"
  )
}

cmd_sync() {
  cmd_pull
  cmd_push "${1:-}"
}

cmd_status() {
  echo "--- symlink ---"
  if [[ -L "$CONFIG_DIR" ]]; then
    c_green "$CONFIG_DIR -> $(readlink "$CONFIG_DIR")"
  else
    c_red "$CONFIG_DIR is NOT a symlink"
  fi
  echo "--- git status ($DOTFILES_DIR) ---"
  git -C "$DOTFILES_DIR" status -sb
}

case "${1:-}" in
  init)   shift; cmd_init "$@" ;;
  link)   cmd_link ;;
  pull)   cmd_pull ;;
  push)   shift; cmd_push "$@" ;;
  sync)   shift; cmd_sync "$@" ;;
  status) cmd_status ;;
  *)
    cat <<EOF
Usage: $0 <command> [args]

Commands:
  init <remote-url>     First-time setup: clone repo + create symlink
  link                  (Re)create the ~/.config symlink
  pull                  Pull remote changes (rebase, autostash)
  push [message]        Commit local changes and push
  sync [message]        pull then push — the everyday command
  status                Show symlink + git status
EOF
    exit 1
    ;;
esac
