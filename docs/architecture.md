# Configuration map

Start with the machine, then follow explicit imports. No directory automatically
enables every file it contains.

| Question | Start here |
| --- | --- |
| Which machines exist, and where do deployments go? | `inventory.json` |
| How are flake outputs constructed? | `flake.nix` |
| What is unique to my Mac or VM? | `hosts/neo/configuration.nix`, `hosts/apoc/configuration.nix` |
| Which user features are enabled? | `home/fs/<host>.nix`, `home/profiles/workstation.nix` |
| Where are macOS defaults and package imports? | `modules/darwin/settings.nix`, `modules/darwin/packages.nix` |
| Where are application package lists? | `hosts/modules/packages/darwin/`, `hosts/modules/packages/linux/` |
| Where is the shared Python environment? | `modules/shared/python.nix` |
| Where are AI settings and ignore defaults? | `home/modules/ai/default.nix`, `home/modules/ai/ignores.nix` |
| Where is the terminal file manager configured? | `home/modules/yazi.nix` (Yazi, enabled by the shared workstation profile) |
| What does a deployment command do? | `justfile`, then `tasks/deploy.just` |
| Where are validation and maintenance commands? | `tasks/quality.just`, `tasks/maintenance.just` |

## Ownership

System modules own operating-system services and system packages. Home Manager
owns user configuration and its program modules. Homebrew owns macOS applications
that are declared there. Keep one owner per application where possible.

Home Manager remains standalone. A system switch is followed by a separate home
switch; the two activations are not atomic. A successful system switch followed by
a failed home switch returns a failure. Re-run `just home-switch neo` after fixing
the problem. The unused Darwin Home Manager integration module remains imported
for compatibility; this change does not migrate ownership of either home.

Compatibility modules at the old import paths forward to the new locations.
Existing flake output names, package selections and state versions are preserved.
The unused, unfinished Fuelcheck overlay was removed; its existing shell command
still uses `nix run` as before.

## Inventory

`inventory.json` is read by Nix and by the Python task helper. Each host has a
platform, user, deployment lane, enabled flag and optional SSH target. `enabled`
controls the default deployment batch, not whether a flake output exists.

To add a host, add its inventory entry, system configuration and user home entry
point. User identity still comes from `users/`. Keep deployment addresses out of
the task recipes.

## Validation and changes

Run `just check` to evaluate native system/home derivations, run flake checks (formatting, Statix, Deadnix and structured files), and run
the deployment regression tests. CI also builds each host on its native platform
without activating it. Together the native jobs cover every declared system and home.
Catppuccin/Starship uses import-from-derivation, so cross-platform home evaluation
can require a remote builder; local checks evaluate native homes only.
There is no remote deployment from CI.

New flake source files must be reviewed and explicitly added with `git add`.
Deployment no longer stages changes on your behalf. Tracked local edits are still
included by Git flakes. Formatting, linting and inspection do not require Doppler;
the existing update/deployment commands retain their Doppler integration.

A file move alone is not proof of equivalent behaviour. Compare derivation paths
with the same lockfile before making claims about evaluation equivalence. Changes
to embedded source paths can legitimately alter derivations even when settings
are identical. Never bump `stateVersion` as part of a directory cleanup.

## Deliberately separate work

AI plugin installation still follows upstream sources and the Claude settings
activation still resets runtime changes to the Nix defaults. Replacing this with
pinned plugin packaging needs a separate migration of the existing installations.
Likewise, the local LiteLLM process aliases remain unchanged; moving them to user
services should be tested on both platforms. These limitations are not fixed by
moving the configuration files.

The package test overrides and nix-homebrew pin retain their existing workarounds.
Revisit them independently of this refactor. Beads remains the task tracker;
Switchyard has not been installed into this repository.

## Yazi

`home/modules/yazi.nix` enables the terminal file manager on neo and apoc,
adapted from [Pratik Thapa's guide](https://medium.com/@pthapa1/yazi-the-best-terminal-file-manager-to-boost-your-productivity-bf13f244756a).
Run `y` in Zsh or Fish to retain the selected directory on exit, or `yazi` for
the plain application. Press `O` (Shift+O) for the interactive opener chooser:
Neovim is available on both hosts, with VS Code also offered on neo.

The Nix package includes FFmpeg, 7-Zip, jq, Poppler, fd, ripgrep, fzf,
zoxide, ImageMagick, Chafa, and resvg. Do not install the guide's Homebrew
dependencies separately. Current Yazi uses FFmpeg rather than the article's
older ffmpegthumbnailer recommendation.

Ghostty supports image previews directly; no WezTerm configuration or
terminal-variable overrides are needed. Run `ya env` inside Ghostty to inspect
the detected image adapter. Test directly in Ghostty before diagnosing any
multiplexer-specific issues. Existing terminal colors are retained; no flavor
or third-party plugin is installed. Use `~` to inspect current keybindings
rather than relying on the 2024 article's potentially outdated shortcuts.
