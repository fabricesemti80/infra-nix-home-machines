# Mac Deployment

This page covers macOS hosts managed by nix-darwin and Home Manager.

## Hosts

The active Darwin outputs live in `flake.nix`:

- `neo`

The matching Home Manager outputs are:

- `fs@neo`

## First-Time Setup

Install Nix, clone this repository, and make sure flakes are available.

```sh
git clone <repo-url>
cd nix-hosts
```

Apply nix-darwin and Home Manager together:

```sh
just darwin-switch neo
```

`darwin-switch` already runs the Home Manager activation. Use `just home-switch neo`
only to retry Home Manager after system activation succeeds.

For another explicitly selected Mac, pass its flake hostname to `darwin-switch`.

## Normal Updates

For the Mac explicitly:

```sh
just quick-update neo
```

`quick-update neo` updates inputs, then builds and switches Neo. `quick-update all`
prints the enabled hosts from inventory and builds/switches them one at a time:
Neo, Apoc, and Trinity. Inputs update once. A failure can leave earlier hosts
updated; `just clean` remains separate and covers all enabled NixOS hosts.

## SSH

Home Manager on Neo declares the SSH client identities in `home/modules/ssh.nix`
and links `~/.ssh/nix-managed.conf`. The existing `~/.ssh/config` includes that
fragment after OrbStack's generated include; its LazySSH-managed PBS entry remains
in place. Keep this include when restoring or migrating the local SSH config.

Nix contains only public keys. The private keys are held in 1Password, whose SSH
agent is limited to the configured 1Password items and the existing Personal
vault. Legacy private-key files remain as fallback until the separate cleanup
task is completed. Git remotes remain HTTPS; GitHub/GitLab SSH entries are for
repositories configured to use SSH.

QNAP's client stanza offers `id_qnap` first with password fallback. The public
key is installed at `/share/homes/admin-fabrice/.ssh/authorized_keys`, and a
key-only login succeeded. Persistence across a NAS reboot remains untested.

Windows/WSL support is tracked separately because Nix is not installed in WSL.

## Build Without Switching

Use a build recipe when checking a change before applying it:

```sh
just darwin-build
just home-build
```

## Logitech MX Master 3

Logi Options+ is declared as the `logi-options+` Homebrew cask in
`hosts/modules/packages/darwin/homebrew.nix`. Install it with
`just darwin-switch neo` (no flake update required), then open Logi Options+
to configure mouse buttons, scrolling, and per-application mappings.

Grant the macOS Accessibility and Input Monitoring permissions requested by
the app. Homebrew's cask notes that a reboot is required. Permissions and mouse
button mappings remain app-managed, not declarative Nix settings.

## Troubleshooting

Show the current hostname, expected flake names, and recent generations:

```sh
just show-config
```

Validate the flake:

```sh
just verify-flake
```

If Home Manager fails after the system switch succeeded, fix the cause and retry
only Home Manager:

```sh
just home-switch neo
```

### Homebrew wrapper pin

`nix-homebrew` is pinned to `09a921d0181146cf6163ec2cc1db7b6fd539a885`.
Revision `c11cccf` causes Homebrew bundle activation to fail with
`key not found: "HOMEBREW_ORIGINAL_BREW_FILE"`. A Renovate package rule excludes
the `nix-homebrew` input so automated digest updates cannot reintroduce it.
Remove that exclusion only after [upstream issue #187](https://github.com/zhaofengli/nix-homebrew/issues/187)
is resolved and the replacement passes an actual Darwin activation.

See [branch validation](branch-validation.md) for changed maintenance behaviour and recovery.
