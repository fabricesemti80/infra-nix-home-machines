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
