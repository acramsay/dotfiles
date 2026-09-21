# Tracking

Living document for tracking online content: GitHub issues/PRs I follow, tools of
interest, useful reference pages, unresolved technical issues, and project ideas.
Maintained together with opencode — use it to ask for status updates, research
alternatives, etc.

## Following

Issues and PRs I'm following the progress of.

| Item           | Tool             | Description                                  | Status             | Last checked |
| -------------- | ---------------- | -------------------------------------------- | ------------------ | ------------ |
| [PR #8675]     | helix            | Steel plugin system                          | open               | 2026-09-18   |
| [#13096]       | helix            | Word splitting for %sh{} expansions          | open               | 2026-09-18   |
| [#15059]       | helix            | Open interactive TUI apps (yazi/lazygit)     | open               | 2026-09-18   |
| [PR #15549]    | helix            | `--list` flag for `:open`                    | open               | 2026-09-18   |
| [#5950]        | helix            | Debugging overhaul                           | open               | 2026-09-18   |
| [DCP #585]     | dcp              | Plugin silently fails to load                | open               | 2026-09-18   |
| [#36279]       | opencode         | Publish v2 through Homebrew                  | open               | 2026-09-18   |
| [#6330]        | opencode         | Plugin-driven generic UI intent channel      | open               | 2026-09-18   |
| [#7006]        | opencode         | `permission.ask` hook never triggers         | open               | 2026-09-18   |
| [AFT #305]     | aft              | Custom LSP servers never deliver diagnostics | **closed (fixed)** | 2026-09-18   |
| [PR #48745]    | opencode         | Add shield-bash to ecosystem plugins list    | open               | 2026-09-18   |
| [awesome #707] | awesome-opencode | Add shield-bash to awesome-opencode plugins  | open               | 2026-09-14   |
| [cafe #16]     | opencode.cafe    | Add shield-bash to opencode.cafe plugin list | open               | 2026-09-14   |

## Tools of interest

Not yet implemented.

| Tool         | Link           | Description                                      |
| ------------ | -------------- | ------------------------------------------------ |
| smith.hx     | [smith.hx]     | —                                                |
| serpl        | [serpl]        | TUI for search and replace                       |
| brow6el      | [brow6el]      | Terminal web browser (CEF, Sixel/Kitty)          |
| scooter.hx   | [scooter.hx]   | Helix find-and-replace plugin                    |
| modeline.hx  | [modeline.hx]  | Helix modeline plugin                            |
| leaf         | [leaf]         | Terminal Markdown previewer                      |
| open-design  | [open-design]  | Open-source Claude Design alternative            |
| worldmonitor | [worldmonitor] | Real-time global intelligence dashboard          |
| executor     | [executor]     | OpenAPI/MCP integration layer for agents         |
| codexbar     | [codexbar]     | AI usage limits in the macOS menu bar            |
| LLMLingua    | [LLMLingua]    | Prompt compression for LLM inference             |
| vikunja      | [vikunja]      | Open-source, self-hostable to-do/task management |
| usememos     | [usememos]     | Note-taking/memo app with knowledge base         |

## Reference pages

Useful sources of info to keep handy.

- [Helix wiki: Language Server Configurations]

## Technical issues

Unresolved.

- Browser keyboard shortcuts are messed up
- Copy/paste shortcuts are inconsistent between linux/macos. Tried adjusting in
  linux, but global shortcuts don't propagate to many apps
- Using Proton VPN (wireguard) breaks WebRTC connections in LibreWolf
- NVIDIA drivers on a temporary locally-built install (repo broken server-side);
  pending official k7.2.4 KMP — see [NVIDIA-RECOVERY.md](NVIDIA-RECOVERY.md)

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
[#6330]: https://github.com/anomalyco/opencode/issues/6330
[#7006]: https://github.com/anomalyco/opencode/issues/7006
[AFT #305]: https://github.com/cortexkit/aft/issues/305
[smith.hx]: https://github.com/kn66/smith.hx
[serpl]: https://github.com/yassinebridi/serpl
[brow6el]: https://tangled.org/janantos.tngl.sh/brow6el
[scooter.hx]: https://github.com/thomasschafer/scooter.hx
[modeline.hx]: https://codeberg.org/gwid/modeline.hx
[leaf]: https://github.com/rivolink/leaf
[open-design]: https://github.com/nexu-io/open-design
[worldmonitor]: https://github.com/koala73/worldmonitor
[executor]: https://github.com/UsefulSoftwareCo/executor
[codexbar]: https://codexbar.app/
[LLMLingua]: https://github.com/microsoft/LLMLingua

[vikunja]: https://vikunja.io/
[usememos]: https://usememos.com/
[PR #48745]: https://github.com/anomalyco/opencode/pull/48745
[awesome #707]: https://github.com/awesome-opencode/awesome-opencode/pull/707
[cafe #16]: https://github.com/R44VC0RP/opencode.cafe/pull/16
[Helix wiki: Language Server Configurations]: https://github.com/helix-editor/helix/wiki/Language-Server-Configurations
