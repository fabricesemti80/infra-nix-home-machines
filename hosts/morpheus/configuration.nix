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
    ../modules/tailscale-router.nix
  ];

  networking.hostName = hostname;
  networking.useDHCP = lib.mkForce false;
  networking.firewall.interfaces.enp0s31f6.allowedTCPPorts = [8000];

  networking.networkmanager.ensureProfiles.profiles.morpheus = {
    connection = {
      id = "morpheus";
      type = "ethernet";
      interface-name = "enp3s0";
      autoconnect = true;
    };
    ipv4 = {
      method = "manual";
      addresses = "10.0.40.19/24";
      gateway = "10.0.40.1";
      dns = "1.1.1.1;8.8.8.8;";
    };
    ipv6.method = "ignore";
  };

  tailscale-router = {
    enable = true;
    advertiseRoutes = ["10.0.0.0/16" "192.168.0.0/16"];
    advertiseExitNode = true;
    ssh = true;
    tags = ["tag:server"];
  };

  services.dbus.implementation = "dbus";

  system.stateVersion = "25.11";
}
