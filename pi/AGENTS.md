# AGENTS.md

Global instructions for pi in every project on this machine. A project's own `AGENTS.md` or `CLAUDE.md` wins where the two conflict.

## Environment

- Ubuntu 24.04, bash and zsh, tmux, nvim, starship. I often work over SSH (Tailscale) inside tmux, from my Macbook.
- Python projects use `uv` (`uv run`, `uv sync`) with a repo-local `.venv`, not bare `pip`.
- `~/.config` is a symlink to the git repo `~/dotfiles/config`; `dotfiles-sync.sh` there commits and syncs it. Shell configs live in `~/.config/zsh` and `~/.config/bash`, not the stubs in `~`.
- My Obsidian vault is always `~/neonoted`; its plugins and snippets sync through the dotfiles repo.

## Working with me

- Ensure that all math is well formatted and will render properly in the terminal.
- When I ask a question ("why is…", "what can I change…"), answer it. Don't edit anything unless I ask.
- For a small, clearly specified change, just make it; don't run a long investigation first. The only exception to this is if there should be proper analysis prior to this change that isn't going to be run in some other workflow or isn't mentioned. In this case, ask whether analysis should be run first.
- For a large task, write a plan with concrete steps before implementing. When I ask you to read a plan, read it, and any other relevant information and code you deem necessary, and ask questions; don't implement until I say so.
- Tell me before making a big interface change (public APIs, endpoints, module layout) instead of making it. Small interface changes can be done directly.
- Never start, stop, restart or redeploy servers, dashboards or services I run. Say when a change needs a restart.
- Keep text short: comments (function comments especially), docs, UI copy and commit messages. Don't add captions, subtitles or explanatory text to a UI unless I ask.

## Git

- Commit only when asked, and push only when asked; "commit" doesn't mean "push".
- Make commits atomic. Keep messages concise; when one commit covers several changes, list them as bullets in the body.
- No AI attribution or `Co-Authored-By` lines.
- Don't create new branches; stay on the branch I'm on. Worktrees are fine for isolation (I use them so agents can work in parallel), but bring the work back onto my branch before pushing, and never push the worktree's branch.

## Subagents and effort

- Ultracode should only be used when explicitly said. Ultracode should also use no more than 6 agents, at an effort equal or less than the calling agent.
- Use `medium` effort for subagents (or `low` for mechanical edits); `high` only when the problem is genuinely hard; never `xhigh`. No subagent above its parent's effort without asking first. Usage is watched.
