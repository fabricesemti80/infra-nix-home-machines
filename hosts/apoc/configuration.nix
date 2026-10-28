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
  services.timesyncd.enable = lib.mkForce true;
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
  kde.enable = true;
  pipewire.enable = true;
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm.wayland.enable = false;
  programs.firefox.enable = true;
  programs.zsh.enable = true; # https://www.zsh.org/

  # Test VM essentials only; user tools live in home/profiles/test-vm.nix.
  environment.systemPackages = with pkgs; [
    curl
    git
    home-manager
    just
  ];

  # Keep the desktop shell and file manager, not a full KDE application suite.
  programs.kde-pim.enable = false;
  services.desktopManager.plasma6.enableQt5Integration = false;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    gwenview
    okular
    kate
    khelpcenter
    konsole
    plasma-browser-integration
    plasma-workspace-wallpapers
    spectacle
    krdp
    plasma-keyboard
    qtvirtualkeyboard
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

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
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userConfig.sshKeys;
  };

  # Passwordless sudo → enables nixos-rebuild over SSH without a tty.
  security.sudo.wheelNeedsPassword = false;

  system.activationScripts.sddmPlasmaSession.text = ''
    mkdir -p /var/lib/sddm
    printf '%s\n' \
      '[Last]' \
      'User=${userConfig.name}' \
      'Session=${config.services.displayManager.sessionData.desktops}/share/xsessions/plasma.desktop' \
      > /var/lib/sddm/state.conf
  '';

  # Parallels VM workarounds: their activation failures propagate as
  # nixos-rebuild switch exit code 4. Disable to keep deploys returning clean.
  systemd.services.prlshprint.enable = false;
  systemd.services.fwupd-refresh.enable = false;

  system.stateVersion = "25.11";
}
