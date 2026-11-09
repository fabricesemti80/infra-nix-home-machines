# Workstation workflow helpers

These Home Manager modules are enabled by the workstation profile on `fs@neo`;
`fs@apoc` uses a separate lean test profile without these workflow helpers. The ideas
come from [TechDufus/dotfiles](https://github.com/TechDufus/dotfiles), adapted
to Nix rather than importing its bootstrap scripts or mise package management.
K9s is included alongside FreeLens as a terminal Kubernetes client.

## Worktrees and OMP

Worktrunk is installed by Home Manager, with Zsh shell integration.
No `wt config shell install` step is needed.

```sh
wt list
wton feat/example -- 'Implement the example'
wto feat/example
wt switch main
```

`wton` creates a worktree and starts a fresh OMP session; `wto` switches to an
existing worktree (or opens the picker without arguments) and runs `omp -c`.
Worktrees live beside the clone under `.worktrees/<repo>/<branch>`.
Worktrunk's merge/remove operations remain explicit commands.

## Herdr

Herdr Core is installed separately from Herdr on macOS and Trinity. Darwin pins
v0.1.14 in `hosts/modules/packages/darwin/system.nix`; Trinity pins Linux x86_64
v0.1.18 in `hosts/modules/packages/linux/herdr-core.nix`. Both expose `hc` and
`herdr-core` as system commands with release checksums pinned in Nix.
Use `hc --help` for commands and `hc --skill` for the agent guide. Update the
Nix package pin rather than running `hc update` against the Nix store.

The Herdr desktop app is the `herdr-app` Homebrew cask in
`hosts/modules/packages/darwin/homebrew.nix` (Apple silicon, from
https://herdr.dev/download/). It installs with `just darwin-switch neo` and
updates itself, so unlike `herdr-core` it is not pinned. Its guide for agents is
`~/.config/herdr-app/AGENTS.md`. The app and the terminal `herdr` (Nix, v0.9.5)
are separate programs; the settings and plugin below configure the terminal one.

`~/.config/herdr/config.toml` is declaratively managed. Its existing
`onboarding = false` and `dracula` theme settings are preserved in
`files/configs/herdr.toml`; Home Manager replaces the file on activation.
Add future local settings there before switching. Reload the configuration in
Herdr with its default Ctrl+B, Shift+R binding.

Home Manager installs the release-matched `herdr` agent skill from the pinned
Herdr input into `~/.agents/skills`, `~/.claude/skills`,
`~/.omp/agent/skills`, and `~/.config/opencode/skills`. Supported agents
discover it automatically after activation and a new agent session. The skill
operates only inside Herdr panes (`HERDR_ENV=1`); it does not control the
separate Herdr Core desktop runtime. See the
[upstream skill guide](https://herdr.dev/tui/docs/agent-skill/).

- Ctrl+B, Alt+P / Alt+N: previous/next agent.
- Ctrl+B, Alt+1–9: focus agent by index.
- Ctrl+B, Alt+G: popup GitHub dashboard (`gh dash`).
- Ctrl+B, Alt+R: toggle the reviewr diff pane.

The dashboard needs an existing GitHub CLI login (`gh auth status`). Herdr's
default pane navigation is retained. Its pinned v0.9.5 supports the
settings used here. The sidebar is compact, sorted by agent priority, and
notifications appear in the terminal. No automatic agent execution is enabled.

### reviewr (diff review)

`home/modules/herdr.nix` installs the
[herdr-reviewr](https://github.com/persiyanov/herdr-reviewr) plugin, pinned to
`v0.49.1`. It shows the diff your agent produced (uncommitted, branch, last turn
or commits) beside the chat; select lines with `v`, comment with `c`, and send
all comments into the agent's input with `s`. It never edits files or posts to a
PR. The PR tab needs `gh` logged in. It also opens by itself when Herdr creates a
worktree workspace. Its theme is set to dracula in
`~/.config/herdr/plugins/config/persiyanov.reviewr/config.toml`.

Plugins live in `~/.config/herdr`, so activation reconciles them: it installs
when the pinned ref is missing, replaces a different ref, leaves a matching one
alone, and only warns if the download fails. Bump the tag in the module to
update. The installer downloads the release binary and checks its published
checksum.

## Kubernetes configuration maintenance

These commands edit local kubeconfig files, without connecting to a cluster.
They are available independently of FreeLens. Zsh also exposes the familiar
`k.importContext` and `k.deleteContext` aliases.

```sh
kubeconfig-helper import -i ~/Downloads/infra.yaml -n infra --context admin
kubeconfig-helper --destination ~/.kube/lab import -i ./app.yaml -n app
kubeconfig-helper delete old-cluster --dry-run
kubeconfig-helper delete old-cluster
```

Import renames the selected context, cluster and user together. It preserves
the current destination context, rejects name collisions, and accepts an
explicit `--server https://...` override. It does not guess remote endpoints or
fetch configurations over SSH. Download a remote configuration separately first.

Delete takes a **cluster name**, previews the associated contexts, and asks for
`yes`; `--yes` skips that prompt. Credentials referenced by surviving contexts
are retained. If the selected context is deleted, the current context is cleared.

The default target is a single `KUBECONFIG` file or `~/.kube/config`. With a
colon-separated `KUBECONFIG`, select one file using `--destination` **before the
subcommand**. Every write creates a unique adjacent backup when the destination
exists, then atomically replaces the file. Both new files and backups use mode
0600. Backups contain credentials: keep them private and delete obsolete copies.

## Git and FZF

Git prunes removed remote branches on fetch, remembers conflict resolutions
(`rerere`), highlights moved lines and defaults new repositories to `main`.
Existing repositories keep their branch names and SSH signing settings.

FZF uses `fd` for file/directory discovery, `bat` and `eza` for bounded previews,
and the existing Catppuccin flavour. `?` toggles previews, Ctrl+A selects all,
Ctrl+E opens selections in Neovim, and Ctrl+Y copies selected paths using
`pbcopy` on macOS or `wl-copy` in a Linux Wayland session. SSH completion can
preview DNS results; variable completion does not preview variable values.

## K9s

Home Manager installs K9s on neo and manages its configuration
and Catppuccin skin using the workstation flavour. Launch `k9s`, or use
`k9s --context <context>` to select a cluster explicitly.

In the Helm view (`:helm`), press `v` to inspect the selected release's
user-supplied values. The shortcut passes the selected namespace and context
to the Nix-managed Helm binary and displays the result in `less` (quit with
`q`). It does not display chart defaults; use Helm's `--all` separately for
computed values. FreeLens remains available.
