{
  config,
  hostname,
  lib,
  pkgs,
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
  services.xserver.videoDrivers = ["modesetting"];
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xrandr}/bin/xrandr --newmode "3840x1200_60.00" 382.25 3840 4080 4488 5136 1200 1203 1213 1245 -hsync +vsync || true
    ${pkgs.xrandr}/bin/xrandr --addmode Virtual-1 "3840x1200_60.00" || true
    ${pkgs.xrandr}/bin/xrandr --output Virtual-1 --mode "3840x1200_60.00" || true
  '';
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Programs / services
  docker.enable = true;
  kde.enable = true;
  pipewire.enable = true;
  services.displayManager.defaultSession = "plasmax11";
  services.displayManager.sddm.wayland.enable = false;
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

  system.activationScripts.sddmPlasmaX11Session.text = ''
    mkdir -p /var/lib/sddm
    printf '%s\n' \
      '[Last]' \
      'User=${userConfig.name}' \
      'Session=${config.services.displayManager.sessionData.desktops}/share/xsessions/plasmax11.desktop' \
      > /var/lib/sddm/state.conf
  '';

  # Parallels VM workarounds: their activation failures propagate as
  # nixos-rebuild switch exit code 4. Disable to keep deploys returning clean.
  systemd.services.prlshprint.enable = false;
  systemd.services.fwupd-refresh.enable = false;

  system.stateVersion = "25.11";
}
