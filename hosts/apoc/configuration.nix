{
  hostname,
  lib,
  userConfig,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../modules/docker.nix
    ../modules/kde.nix
    ../modules/pipewire.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = hostname;
  networking.useDHCP = lib.mkForce false;
  networking.networkmanager.enable = true;

  # Locale / time
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Console / X11 keyboard
  console.keyMap = "uk";
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Programs / services
  docker.enable = true;
  kde.enable = true;
  pipewire.enable = true;
  services.printing.enable = true;
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # SSH (key-only)
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Allow flakes + trust nix-community cachix so first-time pushes of
  # pre-commit-hooks etc. don't get rejected by `require-sigs = true`.
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # User (self-declared, not via vm-generic)
  users.users.${userConfig.name} = {
    isNormalUser = true;
    description = userConfig.fullName;
    extraGroups = ["networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = userConfig.sshKeys;
  };

  # Passwordless sudo → enables nixos-rebuild over SSH without a tty.
  security.sudo.wheelNeedsPassword = false;

  # Parallels VM workarounds: their activation failures propagate as
  # nixos-rebuild switch exit code 4. Disable to keep deploys returning clean.
  systemd.services.prlshprint.enable = false;
  systemd.services.fwupd-refresh.enable = false;

  system.stateVersion = "25.11";
}
