# Commands

`just --list` shows the daily commands. Advanced and compatibility recipes remain
callable but are hidden to keep the list short. Run `just --show <recipe>` to inspect
one. Implementation is split across `tasks/deploy.just`, `tasks/maintenance.just`
and `tasks/quality.just`.

| Command | Purpose |
| --- | --- |
| `just quick-update neo` | Update inputs, build and switch after successful builds |
| `just darwin-build neo` | Build system and home without activation |
| `just darwin-switch neo` | Switch using the current lockfile |
| `just home-build neo` / `just home-switch neo` | Build/switch only the home |
| `just check` | Evaluate native outputs, run flake checks and deployment tests |
| `just verify-flake` | Run flake checks only |
| `just fmt` | Format Nix files |
| `just run-hooks` | Run configured pre-commit checks |
| `just hosts` | Show machine platforms and SSH destinations |
| `just show-config` | Show local configuration/generation information |
| `just brew-update` | Intentionally upgrade Homebrew packages |
| `just clean` | Prune >30-day local system/user generations and enabled NixOS hosts, including apoc |

`quick-update neo` checks the source tree and `nom`, updates shared flake inputs,
then builds and switches only the selected hosts. It does not clean generations.
`just update` alone only updates flake inputs.

`just clean` is a separate task. It uses sudo for root-owned Darwin system
generations, expires local Home Manager generations, and collects Nix garbage;
it also cleans enabled NixOS hosts, including apoc. The 30-day retention keeps
current and recent generations. A cleanup failure stops `just clean`.

Nix build and switch commands pass output through `nom` (`nix-output-monitor`):
successful builds are summarized as a dependency/progress tree, while failed
derivations and their diagnostics stay visible. `nom` is installed in the Home
Manager environment and the repository dev shell. Full derivation logs remain
available with `nix log <derivation>`.

Remote Home Manager builds run `nom` on the target so it reads the target's Nix
store; before `nom` is installed there, they fall back to native Nix output.

Build, switch, and quick-update recipes check for `nom` before running a build,
activation, or input update. If it is unavailable, they stop with a bootstrap hint.
Before Home Manager's first activation, or from a plain shell, use the repository
dev shell:

```sh
nix develop --command just quick-update neo
```

This runs the full update workflow—input update, build, and switch—but not
generation cleanup. Run `just clean` separately when you want to reclaim space.

`quick-update` without a host still targets every enabled machine. Host filters
accept comma-separated names. The remote NixOS commands remain available:
`just nixos-build apoc`, `just nixos-switch apoc`, `just nixos-home-build apoc`
and `just nixos-home-switch apoc`.

Advanced recipes include `repl`, `lint`, `lint-fix`, `deadnix`, `deadnix-fix` and
`install-hooks`. Existing `*-all`, `darwin-switch-neo` and
`home-switch-neo` compatibility recipes remain available.

Failures and unreachable selected hosts return a non-zero status. Aggregate
commands attempt remaining hosts before returning failure. Deployments never stage
files automatically; review and add new flake sources explicitly.

See the [configuration map](architecture.md) and [branch validation guide](branch-validation.md).
