# Host Configuration: neo
# Purpose: MacBook Pro specific settings
# Platform: macOS (Apple Silicon)
{userConfig, ...}: {
  imports = [
    ../modules/ai-tools.nix
    ../modules/avatar.nix
    ../modules/darwin-common.nix
    ../modules/mac-common.nix
    ../modules/parallels.nix
  ];

  # Enable TouchID and WatchID authentication for sudo
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
    enable = true;
  };

  # Machine-specific dock settings
  system.defaults.dock = {
    orientation = "left";
    autohide = false;
    persistent-apps = [
      # Browsers
      "/Applications/Brave Browser.app"
      "/Applications/Safari.app"
      {spacer = {small = true;};}

      # Terminals and development
      # "/Applications/cmux.app"
      # "/Applications/Kiro.app"
      # "/Applications/LM Studio.app"
      # "/Applications/Nix Apps/OpenCode.app"
      "/Applications/Ghostty.app"
      "/Applications/Warp.app"
      "/Applications/Herdr.app"
      "/Applications/Visual Studio Code.app"
      # "/Applications/Lens.app"
      "/Applications/Freelens.app"
      {spacer = {small = true;};}

      # Communication
      "/Applications/Slack.app"
      "/Applications/WhatsApp.app"
      {spacer = {small = true;};}

      # Files and virtualization
      "/Applications/Commander One.app"
      # "/Applications/OrbStack.app"
      "/Applications/Parallels Desktop.app"
      {spacer = {small = true;};}

      # Notes
      # "/Applications/1Password.app"
      "/Applications/Obsidian.app"
    ];
  };

  # Declare primary user
  system.primaryUser = "${userConfig.name}";

  # Set hostname
  networking.hostName = "neo";

  # System state version
  system.stateVersion = 5;
}
