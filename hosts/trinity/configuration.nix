{
  hostname,
  userConfig,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
    ../modules/packages/linux/herdr-core.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  # Lets the wheel user copy flake sources for remote Home Manager builds.
  nix.settings.trusted-users = ["root" "@wheel"];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [
    {
      address = "10.0.40.50";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.0.40.1";
  networking.nameservers = ["1.1.1.1"];
  networking.networkmanager.enable = false;

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };

  programs.zsh.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.${userConfig.name} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = userConfig.sshKeys;
  };
  users.users.root.openssh.authorizedKeys.keys = userConfig.sshKeys;
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  services.getty.autologinUser = null;

  system.stateVersion = "25.11";
}
