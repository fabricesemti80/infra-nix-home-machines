# Commands

`just --list` shows the daily commands. Advanced and compatibility recipes remain
callable but are hidden to keep the list short. Run `just --show <recipe>` to inspect
one. Implementation is split across `tasks/deploy.just`, `tasks/maintenance.just`
and `tasks/quality.just`.

| Command | Purpose |
| --- | --- |
| `just quick-update neo` | Clean old generations, update inputs, build and switch after successful builds |
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

`quick-update neo` checks the source tree, then runs `just clean` locally and on all
enabled NixOS hosts, including apoc, before updating shared flake inputs. Cleanup
uses sudo for root-owned Darwin system generations, expires local Home Manager
generations, and collects Nix garbage. It keeps the current and last 30 days of
generations. Cleanup failure stops the update; a build failure prevents switching.
`just update` alone does not clean generations.
Nix build and switch commands pass output through `nom` (`nix-output-monitor`):
successful builds are summarized as a dependency/progress tree, while failed
derivations and their diagnostics stay visible. `nom` is installed in the Home
Manager environment and the repository dev shell. Full derivation logs remain
available with `nix log <derivation>`.

Deployment recipes check for `nom` before cleanup, builds, or activation and stop
with a bootstrap hint if it is unavailable. Before Home Manager's first activation,
or from a plain shell, use the repository dev shell:

```sh
nix develop --command just quick-update neo
```

This runs the full update workflow, including 30-day cleanup on the Mac and enabled
NixOS hosts, flake updates, builds, and switching; it is not only a shell bootstrap.

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
