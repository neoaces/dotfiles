#!/usr/bin/env bash
#
# dotfiles-sync.sh — manage and sync your entire ~/.config directory between
# machines via git. ~/.config becomes a symlink to a git repo; this script
# wraps the day-to-day git commands.
#
# Usage:
#   ./dotfiles-sync.sh init <git-remote-url>    First-time setup on a machine
#                                                 (clones the repo + creates the symlink)
#   ./dotfiles-sync.sh deps                      Install nvim build deps (C compiler,
#                                                 tree-sitter CLI, Rust for blink.cmp)
#   ./dotfiles-sync.sh link                      (Re)create the ~/.config symlink
#   ./dotfiles-sync.sh pull                      Pull remote changes only
#   ./dotfiles-sync.sh push ["commit message"]   Commit + push local changes only
#   ./dotfiles-sync.sh sync ["commit message"]   Pull, then commit + push — the everyday command
#   ./dotfiles-sync.sh status                    Show repo + symlink status
#   ./dotfiles-sync.sh migrate                   Move an old ~/dotfiles/config repo to ~/dotfiles
#                                                 (also runs automatically before link/pull/push/sync)
#
# Config (override via env vars if you want a different layout):
#   DOTFILES_DIR   Where the git repo lives locally   (default: ~/dotfiles)
#   CONFIG_DIR     Where apps expect their configs      (default: ~/.config)
#
# Zsh: init/link also write ~/.zshenv with `export ZDOTDIR=$CONFIG_DIR/zsh`
# so zsh reads its .zshrc from the synced config/zsh folder.
# Bash: init/link also append a line to ~/.bashrc that sources
# $CONFIG_DIR/bash/.bashrc (the synced file).
# Obsidian: init/link also symlink the vault's .obsidian/{plugins,snippets}
# (vault at $OBSIDIAN_VAULT, default ~/neonoted) to $CONFIG_DIR/obsidian-vault.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config}"
# Previous layout (repo nested one level down); `migrate` moves it to $DOTFILES_DIR
OLD_DOTFILES_DIR="$HOME/dotfiles/config"

c_green()  { printf '\033[32m%s\033[0m\n' "$1"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
c_red()    { printf '\033[31m%s\033[0m\n' "$1"; }

current_branch() {
  git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD
}

# Old layout: repo at ~/dotfiles/config, ~/.config -> ~/dotfiles/config.
# New layout: repo at ~/dotfiles,        ~/.config -> ~/dotfiles.
# Anything else living in the old ~/dotfiles is kept in ~/dotfiles.old.<ts>.
cmd_migrate() {
  [[ -d "$OLD_DOTFILES_DIR/.git" && "$DOTFILES_DIR" == "$HOME/dotfiles" ]] || return 0

  local ts parent
  ts="$(date +%Y%m%d%H%M%S)"
  parent="$HOME/dotfiles.old.$ts"
  c_yellow "Migrating repo $OLD_DOTFILES_DIR -> $DOTFILES_DIR"
  mv "$HOME/dotfiles" "$parent"
  mv "$parent/config" "$DOTFILES_DIR"
  if rmdir "$parent" 2>/dev/null; then
    :
  else
    c_yellow "Other files from the old ~/dotfiles kept in $parent"
  fi

  if [[ -L "$CONFIG_DIR" ]]; then
    rm "$CONFIG_DIR"
    ln -s "$DOTFILES_DIR" "$CONFIG_DIR"
    c_green "Relinked $CONFIG_DIR -> $DOTFILES_DIR"
  fi

  # launchd agents copied from the repo (e.g. tmux/mac-clipboard-sync.plist)
  # may still hardcode the old path
  local agent
  for agent in "$HOME"/Library/LaunchAgents/*.plist; do
    [[ -f "$agent" ]] && grep -qF 'dotfiles/config/' "$agent" || continue
    sed -i.bak 's#dotfiles/config/#.config/#g' "$agent" && rm -f "$agent.bak"
    launchctl unload "$agent" 2>/dev/null || true
    launchctl load "$agent" 2>/dev/null || true
    c_green "Updated + reloaded $agent"
  done

  c_green "Migration complete. Open a new shell to pick up the new aliases."
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

cmd_zsh() {
  local zshenv="$HOME/.zshenv"
  local line='export ZDOTDIR="$HOME/.config/zsh"'
  mkdir -p "$DOTFILES_DIR/zsh"
  if grep -qsF "$line" "$zshenv"; then
    c_yellow "ZDOTDIR already set in $zshenv"
  else
    printf '%s\n' "$line" >> "$zshenv"
    c_green "Set ZDOTDIR in $zshenv -> \$HOME/.config/zsh"
  fi
}

cmd_bash() {
  local bashrc="$HOME/.bashrc"
  local line='[ -f "$HOME/.config/bash/.bashrc" ] && . "$HOME/.config/bash/.bashrc"'
  mkdir -p "$DOTFILES_DIR/bash"
  if grep -qsF "$line" "$bashrc"; then
    c_yellow "Synced bashrc already sourced from $bashrc"
  else
    printf '\n# Synced bashrc (dotfiles-sync.sh)\n%s\n' "$line" >> "$bashrc"
    c_green "Added source line to $bashrc -> \$HOME/.config/bash/.bashrc"
  fi
}

OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/neonoted}"

cmd_obsidian() {
  local dir="$OBSIDIAN_VAULT/.obsidian" src
  if [[ ! -d "$OBSIDIAN_VAULT" ]]; then
    c_yellow "No vault at $OBSIDIAN_VAULT — skipping Obsidian links."
    return
  fi
  mkdir -p "$dir"
  for sub in plugins snippets; do
    # Relative, so the link stays valid if the vault itself is synced to a
    # machine with a different $HOME (e.g. /home/x vs /Users/x)
    src="../../.config/obsidian-vault/$sub"
    mkdir -p "$DOTFILES_DIR/obsidian-vault/$sub"
    if [[ -L "$dir/$sub" ]]; then
      if [[ "$(readlink "$dir/$sub")" == "$src" && -d "$dir/$sub" ]]; then
        c_yellow "Obsidian $sub already linked"
        continue
      fi
      rm "$dir/$sub"
    fi
    if [[ -e "$dir/$sub" ]]; then
      local backup="$dir/$sub.bak.$(date +%Y%m%d%H%M%S)"
      mv "$dir/$sub" "$backup"
      c_yellow "Existing $dir/$sub backed up to $backup"
    fi
    ln -s "$src" "$dir/$sub"
    c_green "Linked $dir/$sub -> $src"
  done
}

TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-0.26.1}"

# Neovim build deps: nvim-treesitter (main) compiles parsers with the
# `tree-sitter` CLI + a C compiler; blink.cmp (main) builds its Rust fuzzy
# matcher with cargo.
cmd_deps() {
  local os arch bin="$HOME/.local/bin"
  os="$(uname -s)"; arch="$(uname -m)"
  mkdir -p "$bin"

  if ! command -v cc >/dev/null; then
    if [[ "$os" == Darwin ]]; then
      xcode-select --install || true
    elif command -v apt-get >/dev/null; then
      sudo apt-get update && sudo apt-get install -y build-essential
    else
      c_red "No C compiler found — install one (gcc/clang) manually."
    fi
  fi

  if ! command -v tree-sitter >/dev/null; then
    case "$os-$arch" in
      Linux-x86_64)  ts=linux-x64 ;;
      Linux-aarch64) ts=linux-arm64 ;;
      Darwin-arm64)  ts=macos-arm64 ;;
      Darwin-x86_64) ts=macos-x64 ;;
      *) c_red "Unsupported platform for tree-sitter CLI: $os-$arch"; return 1 ;;
    esac
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-$ts.gz" \
      | gunzip > "$bin/tree-sitter"
    chmod +x "$bin/tree-sitter"
    c_green "Installed tree-sitter $TREE_SITTER_VERSION -> $bin/tree-sitter"
  fi

  if ! command -v cargo >/dev/null && [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
    c_green "Installed Rust toolchain -> ~/.cargo/bin"
  fi
}

cmd_init() {
  local remote="${1:-}"
  if [[ -z "$remote" ]]; then
    c_red "Usage: $0 init <git-remote-url>"
    exit 1
  fi

  cmd_migrate
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    c_yellow "Repo already exists at $DOTFILES_DIR — skipping clone."
  else
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$remote" "$DOTFILES_DIR"
  fi

  cmd_link
  cmd_zsh
  cmd_bash
  cmd_obsidian
  cmd_deps
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
  local before after
  before="$(git -C "$DOTFILES_DIR" hash-object "$DOTFILES_DIR/dotfiles-sync.sh")"
  cmd_pull
  after="$(git -C "$DOTFILES_DIR" hash-object "$DOTFILES_DIR/dotfiles-sync.sh")"
  # The pull updated this script — hand off to the new version so its
  # changes (e.g. a migration) apply in this same run
  if [[ "$before" != "$after" ]]; then
    c_yellow "dotfiles-sync.sh changed upstream — re-running the new version"
    exec "$DOTFILES_DIR/dotfiles-sync.sh" _post-pull "${1:-}"
  fi
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
  deps)   cmd_deps ;;
  link)   cmd_migrate; cmd_link; cmd_zsh; cmd_bash; cmd_obsidian ;;
  pull)   cmd_migrate; cmd_pull ;;
  push)   shift; cmd_migrate; cmd_push "$@" ;;
  sync)   shift; cmd_migrate; cmd_sync "$@" ;;
  status) cmd_status ;;
  migrate) cmd_migrate ;;
  _post-pull) shift; cmd_migrate; cmd_link; cmd_zsh; cmd_bash; cmd_obsidian; cmd_push "$@" ;;
  *)
    cat <<EOF
Usage: $0 <command> [args]

Commands:
  init <remote-url>     First-time setup: clone repo + create symlink
  deps                  Install nvim build deps (cc, tree-sitter, Rust)
  link                  (Re)create the ~/.config symlink (+ zsh/bash/Obsidian links)
  pull                  Pull remote changes (rebase, autostash)
  push [message]        Commit local changes and push
  sync [message]        pull then push — the everyday command
  status                Show symlink + git status
  migrate               Move an old ~/dotfiles/config repo to ~/dotfiles
EOF
    exit 1
    ;;
esac
