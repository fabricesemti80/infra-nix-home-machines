# Darwin AeroSpace Configuration

The configuration source is `files/configs/aerospace.toml`. Home Manager installs
it as `~/.aerospace.toml` through `home/modules/darwin-aerospace.nix`. Dock pins are
declared separately in `hosts/neo/configuration.nix`.

## Workspace Allocation

Dock-pinned apps use mnemonic workspaces:

| Apps | Workspace | Focus shortcut |
| --- | --- | --- |
| Brave, Safari | B — Browsers | `alt-b` |
| Commander One | F — Files | `alt-f` |
| Ghostty, Warp, Submarine | T — Terminals / SSH | `alt-t` |
| Parallels Desktop | P — Parallels and VMs | `alt-p` |
| Codex (the Nix app named ChatGPT), OpenCode | A — AI | `alt-a` |
| WhatsApp | M — Messaging | `alt-m` |
| Freelens | K — Kubernetes | `alt-k` |
| Visual Studio Code | C — Code editors | `alt-c` |
| Obsidian | N — Notes | `alt-n` |

Freelens matches `app.freelens.Freelens`; Submarine matches `com.submarine.app`.
Both explicitly use tiling. Microsoft Remote Desktop has one rule, targeting
W — Work, rather than conflicting P and W rules.

Numeric workspaces 1–5 remain available for manually grouped project windows.
New Ghostty windows start on T; the rule does not enforce one window per workspace.
Use `alt-shift-<workspace>` to move an existing window and switch to its destination.

Monitor assignments remain Dell-first with `main` fallback. With only the built-in
display connected, workspaces use that fallback. The root layout is `tiles` with
automatic orientation: horizontal on wide displays and vertical on tall displays.

## Applying Changes

```sh
just home-switch neo
aerospace reload-config --dry-run
aerospace reload-config
aerospace list-windows --all --format '%{app-name} | %{app-bundle-id} | %{workspace}'
```

Detection rules apply to newly detected windows; reloading does not retroactively
relocate existing ones. To confirm the managed source and live app placements:

```sh
aerospace config --config-path
shasum -a 256 ~/.aerospace.toml files/configs/aerospace.toml
```

The remaining keybindings, gaps, service-mode commands, and utility-app rules are
maintained in the TOML source rather than duplicated here.
