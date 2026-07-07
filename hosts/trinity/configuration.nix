# Trinity (Proxmox/QEMU VM) — aligned with the other NixOS hosts.
{
  inputs,
  hostname,
  lib,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    ../modules/ai-tools.nix
    ../modules/nixos-server-common.nix
    ../modules/tailscale.nix
  ];

  networking.hostName = hostname;
  networking.useDHCP = lib.mkForce false;
  networking.usePredictableInterfaceNames = false;
  networking.firewall.interfaces.eth0.allowedTCPPorts = [8000];

  networking.networkmanager.ensureProfiles.profiles.trinity = {
    connection = {
      id = "trinity";
      type = "ethernet";
      interface-name = "eth0";
      autoconnect = true;
      autoconnect-priority = 10;
    };
    ipv4 = {
      method = "manual";
      addresses = "10.0.40.61/24";
      gateway = "10.0.40.1";
      dns = "1.1.1.1;8.8.8.8;";
    };
    ipv6.method = "ignore";
  };

  tailscale.enable = true;

  # Keep the existing dbus implementation; switching to broker triggers a switch inhibitor.
  services.dbus.implementation = "dbus";

  # VM-specific: do not touch EFI variables, unlike physical hosts.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  system.stateVersion = "25.11";
}
