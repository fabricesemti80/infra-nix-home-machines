# Commands

`just --list` shows the daily commands. Advanced and compatibility recipes remain
callable but are hidden to keep the list short. Run `just --show <recipe>` to inspect
one. Implementation is split across `tasks/deploy.just`, `tasks/maintenance.just`
and `tasks/quality.just`.

| Command | Purpose |
| --- | --- |
| `just quick-update neo` | Update inputs and switch the Mac system and home |
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
| `just clean` | Expire old generations using a 30-day window |

`quick-update` without a host still targets every enabled machine. Host filters
accept comma-separated names. The remote NixOS commands remain available:
`just nixos-build apoc`, `just nixos-switch apoc`, `just nixos-home-build apoc`
and `just nixos-home-switch apoc`.

Advanced recipes include `quick-update-lane`, `repl`, `lint`, `lint-fix`, `deadnix`,
`deadnix-fix` and `install-hooks`. Existing `*-all`, `darwin-switch-neo` and
`home-switch-neo` compatibility recipes remain available.

Failures and unreachable selected hosts return a non-zero status. Aggregate
commands attempt remaining hosts before returning failure. Deployments never stage
files automatically; review and add new flake sources explicitly.

See the [configuration map](architecture.md) and [branch validation guide](branch-validation.md).
