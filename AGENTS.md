# AGENTS.md

> This file is **repo-specific** guidance for the dotfiles project. It is *not* the global
> AGENTS.md — that lives at `.config/opencode/AGENTS.md` and applies to every session. Edit here
> only for dotfiles-specific rules; edit there for global defaults.

Personal dotfiles. Config files live in the repo and are **symlinked** into `$HOME` by
Task.

When locating a file to read or edit, look in the local repo first; only fall back to `~/` if the
relevant file is not found here. Editing the repo copy is what propagates through the symlinks.

## Layout

- Files at repo root (e.g. `.zshrc`, `.gitconfig`, `.config/**`) symlink to the same path under
  `$HOME`.
- `darwin/home/**` and `linux/home/**` hold OS-specific files; their contents map onto `$HOME` on
  the matching platform only. Put platform-specific config here, not at the root.
- `Taskfile.yaml` is itself symlinked to `~/Taskfile.yaml`; tasks resolve the real repo via
  `realpath`, so `dir:` and path vars look indirect on purpose — don't "simplify" them to relative
  paths.
- `Taskfile.opensuse-tumbleweed.yaml` and `k3d/Taskfile.k3d.yaml` are optional includes (aliases
  `ot`, `k3d`).

## Design principles

The repo is built around a few consistent patterns. Match them when adding config.

- **Symlink, don't copy.** Every config is edited in the repo and symlinked into `$HOME` by
  `task cs`. New root files are picked up automatically — there is no manifest to update.
- **Three-layer override chain.** Config splits into committed base → OS-specific → machine-local
  (uncommitted). Preserve this ordering when extending a file:
  - `.gitconfig` includes `~/.gitconfig.os` (from `{darwin,linux}/home/.gitconfig.os`) then
    `~/.gitconfig.local`. Local is last so it wins.
  - `.zshrc` sources `~/.${SHELL_NAME}rc.local` at the very end (comment says so — keep it last).
  - Put shared config in the base; only OS- or machine-specific deltas go in the override layers.
- **Platform selection over duplication.** One source, branched by OS: `.zshrc`/`.bashrc` are the
  same symlinked file (must stay valid for both shells); `Brewfile` guards with `OS.mac?` /
  `OS.linux?`; OS-only files live under `darwin/home/**` and `linux/home/**`.
- **Declare, don't install ad hoc.** Packages belong in `Brewfile`; system/service setup belongs in
  a task. `.service`/`.plist` files auto-register with systemd/launchd on `task cs`.
- **Require config over scripting.** Reach for a tool's own config (git aliases, task definitions,
  dprint) before shell glue.
