# Trinity NixOS VM

`trinity` is a headless x86_64 NixOS VM on Proxmox `pve-00` (VMID 4050),
using the untagged native network on `vmbr0` (VLAN 40), address `10.0.40.50/24`,
gateway `10.0.40.1`, and DNS `1.1.1.1`. Do not configure a VLAN tag on the VM
NIC: the bridge's native network is already VLAN 40. The VM uses UEFI, a 1 GiB
EFI system partition and ext4 root on its single 80 GiB disk. Disko installation
is destructive to `/dev/sda`; verify the target disk before installing.

The VM allocation is 4 vCPU and 8 GiB RAM.

## Provision and install

The sibling `home-dc-terraform` repository creates the VM from a pinned Debian
cloud image (cloud-init sets the static IP and SSH key) and converts it to this
flake's `trinity` configuration with `nixos-anywhere`. From that repository:

```sh
task proxmox:trinity-plan     # optional review
task proxmox:trinity-deploy   # create VM, wait for SSH, install NixOS, verify
```

No console or GUI step is needed. The install script refuses any target that is
not the fresh, not-yet-installed Trinity bootstrap VM (it never reinstalls a
host that already runs NixOS). Disko erases the bootstrap disk, which is
intended. After installation use `task proxmox:trinity-status`,
`task proxmox:trinity-ssh`, and, once the new host source files are staged or
committed (the Git-flake workflow rejects untracked sources; the initial install
uses `path:.`), `task proxmox:trinity-configure`.

See [the Terraform operator guide](../../home-dc-terraform/proxmox/README.md#trinity-nixos-vm)
for details.

## Ongoing management

Once installation has completed and SSH is reachable:

```sh
just nixos-build trinity
just nixos-switch trinity
just nixos-home-build trinity
just nixos-home-switch trinity
```

Trinity's `fs` account now accepts its dedicated `id_trinity` public key in
addition to the legacy keys. The public key is declared in `users/fs.nix` and
installed by `just nixos-switch trinity`; root access continues to use the legacy
keys. Keep the old client key until the separate cleanup task.

## AI terminal workstation

Trinity's Home Manager profile imports the shared terminal-workstation setup:
Zsh, Starship prompt, shell aliases, Herdr/`hc`, OMP, Claude Code, Codex, Git,
tmux and the command-line tools. It adds Claude Code and Codex as native Linux
Nix packages; credentials are deliberately not stored in Nix. Log in on Trinity
with `claude` and `codex login`. OMP profiles are available through `omp-codex`,
`omp-opencode`, `omp-claude` and `omp-mixed`; authenticate each provider on this
host. Ghostty is intentionally omitted: Trinity is headless, so connect from the
terminal app on your current machine over SSH.

Trinity also installs `direnv`. In a trusted Kubernetes project with an `.envrc`,
run `direnv allow` once and start a new shell after Home Manager activation if
needed. For `home-dc-kubernetes`, `.envrc` selects the project's `kubeconfig`;
without it, `kubectl` can fall back to `localhost:8080`. The kubeconfig and
other credentials remain outside this repository and are not provisioned by Nix.

Connect from the trusted network over SSH, then start Herdr's terminal UI:

```sh
ssh fs@10.0.40.50
herdr
```

Herdr reviewr is installed at user scope and opens for worktree workspaces; use
the review pane to inspect diffs and send line comments back to the active agent.
The Herdr desktop app is not installed on this headless VM; use it on neo to
attach to remote work if preferred.

Preview the changes with `just nixos-build trinity`; apply them with
`just nixos-switch trinity`. The switch also activates Home Manager. No disk
repartitioning runs during a normal switch.
