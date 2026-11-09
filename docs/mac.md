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

`home/modules/ssh.nix` declares the same SSH host blocks for every machine (Neo,
Trinity, Apoc) through the shared terminal profile, so you connect to a target
the same way from any of them. It writes `~/.ssh/nix-managed.conf` and the
public keys under `~/.ssh`.

- **Neo:** `~/.ssh/config` is hand-maintained and includes that fragment after
  OrbStack's include; its LazySSH-managed PBS entry remains. Keep the include
  when restoring the file. Blocks set `IdentityAgent` to the 1Password app, and
  `ForwardAgent` names the 1Password socket explicitly (a bare `yes` forwards
  `$SSH_AUTH_SOCK`, which can be unset) for Trinity and Apoc only. 1Password must
  be running and unlocked with its SSH agent on. If its socket refuses
  connections, no agent is forwarded. Only Apoc's managed block explicitly
  includes a legacy private-key fallback (`~/.ssh/id_macbook_fs`); do not assume
  the other managed blocks can fall back to local private keys.
- **Trinity and Apoc:** no 1Password app (and its agent cannot run headless), so
  they use the agent forwarded from Neo. Nix owns their `~/.ssh/config`. SSH Neo
  to the host first (`ssh trinity`), then connect onward from there; each key use
  prompts for approval in 1Password on Neo.

  **Herdr:** panes and `hc exec` commands run under the long-lived `herdr-core`
  daemon on Trinity (parent: systemd), not under the SSH login that connected the
  app, so they never inherit that login's agent. Every Linux host therefore uses a
  stable link, `~/.ssh/auth-sock`, as its `IdentityAgent` and `SSH_AUTH_SOCK`.
  `~/.ssh/agent-link` repoints it at a live forwarded socket when it dangles. It
  runs from `~/.ssh/rc` (every login, including Herdr's transport), from the zsh
  prompt, and from a `Match exec` in the ssh config (every `ssh` invocation).
  Onward SSH from a pane works while Herdr or any `ssh trinity` session is open.
  With no live forwarded session the link dangles and SSH reports
  `Load key ...: invalid format` before asking for a password. Run `exec zsh` in
  a pane that started before this change. A new host also needs its host key
  trusted once (`known_hosts` is not managed).

  Recovery currently checks whether `~/.ssh/auth-sock` points to a socket,
  not whether that agent responds. A nonresponsive socket that still exists can
  prevent recovery. With a live forwarded session open, remove only the stale
  `~/.ssh/auth-sock` symlink and run `~/.ssh/agent-link` to select a responding
  agent. Do not remove the sockets in `~/.ssh/agent`.

Nix contains only public keys. The managed SSH identities use private keys held
in 1Password. The Mac's agent configuration exposes the named items from the
`ssh-keys` vault **and SSH keys in the Personal vault**; it is not restricted to
the named items alone. `macbook-fs`, `fs-home-rsa`, and `git-signing-fs` remain
listed for legacy access and signing. These declarations do not archive keys
or remove local private-key files.
Git remotes remain HTTPS; GitHub/GitLab SSH entries are for repositories
configured to use SSH.

Deploy recipes connect to the `target` in `inventory.json` (for example
`fs@10.211.55.8`), not to the host alias. Each managed `Host` block must
therefore also list that IP (`Host apoc 10.211.55.8`); otherwise SSH ignores the
block, falls back to default `~/.ssh/id_*` files, and the host looks offline.

QNAP's client stanza offers `id_qnap` first with password fallback. The public
key is installed at `/share/homes/admin-fabrice/.ssh/authorized_keys`, and a
key-only login succeeded. Persistence across a NAS reboot remains untested.

The managed PBS block connects the alias `proxmox-pbs-0` to `10.0.40.20` as
root and selects `id_proxmox_pbs_0.pub` (`sshKeysByHost.pbs`). It currently
matches **only the alias**, not the IP: use `ssh proxmox-pbs-0` to select this
identity. Direct connections to `10.0.40.20` do not receive the managed block's
identity settings. This is an exception to the IP-matching requirement above.
The client configuration does not install or replace keys on PBS; server-side
key enrollment must be verified separately.

Git commit signing in this PR still sets `user.signingkey` to
`~/.ssh/id_gitsign_fs`, with signing enabled and the default SSH signing
program. This configuration does not declare a `.pub` signing-key file or a
1Password signer wrapper. **Keep the existing signing key available; do not
archive or delete `~/.ssh/id_gitsign_fs` based on this deployment.** A separate
public-key/agent signing migration must be included, activated, and verified
with an actual signed commit before retiring the local key.

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
