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
  be running and unlocked with its SSH agent on; if its socket refuses
  connections, SSH silently falls back to the legacy key files and forwards no
  agent.
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

Nix contains only public keys. The private keys are held in 1Password, whose SSH
agent is limited to the configured items of the `ssh-keys` vault; the Personal
vault is no longer exposed. Retired keys are archived in 1Password and their
private key files were moved to `~/.ssh/archive`. `macbook-fs`, `fs-home-rsa`
and `git-signing-fs` stay served on purpose (legacy fallback and commit signing).
Git remotes remain HTTPS; GitHub/GitLab SSH entries are for repositories
configured to use SSH.

Deploy recipes connect to the `target` in `inventory.json` (for example
`fs@10.211.55.8`), not to the host alias. Each managed `Host` block must
therefore also list that IP (`Host apoc 10.211.55.8`); otherwise SSH ignores the
block, falls back to default `~/.ssh/id_*` files, and the host looks offline.

QNAP's client stanza offers `id_qnap` first with password fallback. The public
key is installed at `/share/homes/admin-fabrice/.ssh/authorized_keys`, and a
key-only login succeeded. Persistence across a NAS reboot remains untested.

The PBS LXC (`10.0.40.20`) has its own dedicated key, `id_proxmox_pbs_0`
(`sshKeysByHost.pbs`), like `pve-00` and Trinity. Its Host block lists the IP
(`Host proxmox-pbs-0 10.0.40.20`) so scripts and Terraform that connect to the IP
get that key. Nix cannot install it in the container: `home-dc-terraform`'s
`pbs-apply` does (`terraform_data.pbs_ssh_key`, through `pve-00` with `pct`) and
makes it the only key the container accepts for root. Until that apply,
use `ssh -t root@pve-00 pct enter 4020`.

Git commit signing uses the 1Password item `git-signing-fs`; no private key file
is kept on disk. `sshKeysByHost.gitsign` is written to `~/.ssh/id_gitsign_fs.pub`
and `user.signingkey` points at it. On the Mac, Git's signer is a small wrapper
that points `ssh-keygen` at the 1Password agent socket (the system shell's
`SSH_AUTH_SOCK` is not that agent), so signing works from any terminal; the first
use per session shows a 1Password approval prompt. 1Password's own `op-ssh-sign`
helper failed from a non-GUI shell and is not used. On Trinity and Apoc the
forwarded agent is already `SSH_AUTH_SOCK`. Before the first switch that adds
this, move any loose `~/.ssh/id_gitsign_fs.pub` aside (Home Manager refuses to
overwrite it); after the switch the old `~/.ssh/id_gitsign_fs` private key file is
no longer used and can be archived.

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
