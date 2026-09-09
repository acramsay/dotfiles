# Tracking

Living document for tracking online content: GitHub issues/PRs I follow, tools of
interest, useful reference pages, unresolved technical issues, and project ideas.
Maintained together with opencode — use it to ask for status updates, research
alternatives, etc.

## Following

Issues and PRs I'm following the progress of.

| Item        | Tool     | Description                                  | Status | Last checked |
| ----------- | -------- | -------------------------------------------- | ------ | ------------ |
| [PR #8675]  | helix    | Steel plugin system                          | open   | 2026-09-07   |
| [#13096]    | helix    | Word splitting for %sh{} expansions          | open   | 2026-09-07   |
| [#15059]    | helix    | Open interactive TUI apps (yazi/lazygit)     | open   | 2026-09-08   |
| [PR #15549] | helix    | `--list` flag for `:open`                    | open   | 2026-09-07   |
| [#5950]     | helix    | Debugging overhaul                           | open   | 2026-09-07   |
| [DCP #585]  | dcp      | Plugin silently fails to load                | open   | 2026-09-07   |
| [#36279]    | opencode | Publish v2 through Homebrew                  | open   | 2026-09-07   |
| [AFT #305]  | aft      | Custom LSP servers never deliver diagnostics | open   | 2026-09-08   |

## Tools of interest

Not yet implemented.

| Tool        | Link          | Description                             |
| ----------- | ------------- | --------------------------------------- |
| smith.hx    | [smith.hx]    | —                                       |
| serpl       | [serpl]       | TUI for search and replace              |
| brow6el     | [brow6el]     | Terminal web browser (CEF, Sixel/Kitty) |
| scooter.hx  | [scooter.hx]  | Helix find-and-replace plugin           |
| modeline.hx | [modeline.hx] | Helix modeline plugin                   |
| leaf        | [leaf]        | Terminal Markdown previewer             |

## Reference pages

Useful sources of info to keep handy.

- [Helix wiki: Language Server Configurations]

## Technical issues

Unresolved.

- Browser keyboard shortcuts are messed up
- Copy/paste shortcuts are inconsistent between linux/macos. Tried adjusting in
  linux, but global shortcuts don't propagate to many apps
- Using Proton VPN (wireguard) breaks WebRTC connections in LibreWolf

## Ideas / next up

- Create TUI plugin for shield bash to switch between sessions
- Migrate to opencode2
- Update personal website with these plugins listed on the projects page

[PR #8675]: https://github.com/helix-editor/helix/pull/8675
[#13096]: https://github.com/helix-editor/helix/issues/13096
[#15059]: https://github.com/helix-editor/helix/issues/15059
[PR #15549]: https://github.com/helix-editor/helix/pull/15549
[#5950]: https://github.com/helix-editor/helix/issues/5950
[DCP #585]: https://github.com/Opencode-DCP/opencode-dynamic-context-pruning/issues/585
[#36279]: https://github.com/anomalyco/opencode/issues/36279
[AFT #305]: https://github.com/cortexkit/aft/issues/305
[smith.hx]: https://github.com/kn66/smith.hx
[serpl]: https://github.com/yassinebridi/serpl
[brow6el]: https://tangled.org/janantos.tngl.sh/brow6el
[scooter.hx]: https://github.com/thomasschafer/scooter.hx
[modeline.hx]: https://codeberg.org/gwid/modeline.hx
[leaf]: https://github.com/rivolink/leaf
[Helix wiki: Language Server Configurations]: https://github.com/helix-editor/helix/wiki/Language-Server-Configurations
