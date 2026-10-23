# Workstation workflow helpers

These Home Manager modules are shared by `fs@neo` and `fs@apoc`. The ideas
come from [TechDufus/dotfiles](https://github.com/TechDufus/dotfiles), adapted
to Nix rather than importing its bootstrap scripts or mise package management.
K9s is included alongside FreeLens as a terminal Kubernetes client.

## Worktrees and OMP

Worktrunk is installed by Home Manager, with Zsh and Fish shell integration.
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

`~/.config/herdr/config.toml` is declaratively managed. If a hand-written file
already exists, back it up and move it aside before activating Home Manager.
Reload the configuration in Herdr with its default Ctrl+B, Shift+R binding.

- Ctrl+B, Alt+P / Alt+N: previous/next agent.
- Ctrl+B, Alt+1–9: focus agent by index.
- Ctrl+B, Alt+G: popup GitHub dashboard (`gh dash`).

The dashboard needs an existing GitHub CLI login (`gh auth status`). Herdr's
normal prefix and pane navigation are retained. Its pinned v0.9.5 supports the
settings used here. The sidebar is compact, sorted by agent priority, and
notifications appear in the terminal. No automatic agent execution is enabled.

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

Home Manager installs K9s on both workstations and manages its configuration
and Catppuccin skin using the shared flavour. Launch `k9s`, or use
`k9s --context <context>` to select a cluster explicitly.

In the Helm view (`:helm`), press `v` to inspect the selected release's
user-supplied values. The shortcut passes the selected namespace and context
to the Nix-managed Helm binary and displays the result in `less` (quit with
`q`). It does not display chart defaults; use Helm's `--all` separately for
computed values. FreeLens remains available.
