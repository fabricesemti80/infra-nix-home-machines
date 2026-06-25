# Trinity (Proxmox/QEMU VM) imports only the QEMU guest module.
# Disk layout is intentionally inherited from the Proxmox cloud image
# (root labelled `nixos`, ESP labelled `ESP`) - see `hosts/modules/qemu-vm.nix`.
{
  imports = [
    ../modules/ai-tools.nix
    ../modules/qemu-vm.nix
  ];
}
