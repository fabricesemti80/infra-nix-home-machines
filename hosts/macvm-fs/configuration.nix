# Host Configuration: macvm-fs
# Purpose: macOS VM specific settings
# Platform: macOS (Apple Silicon VM)
{pkgs, ...}: {
  imports = [
    ../modules/avatar.nix
    ../modules/darwin-common.nix
    ../modules/mac-common.nix
  ];

  # Enable TouchID authentication for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Machine-specific settings
  system.defaults = {
    # Disable mouse acceleration for VM
    ".GlobalPreferences"."com.apple.mouse.scaling" = -1.0;

    # VM-specific dock settings
    dock = {
      autohide = true;
      persistent-apps = [
        "/Applications/Brave Browser.app"
        "/Applications/OrbStack.app"
        "${pkgs.alacritty}/Applications/Alacritty.app"
        "${pkgs.vscode}/Applications/Visual Studio Code.app"
        "${pkgs.obsidian}/Applications/Obsidian.app"
      ];
    };
  };

  # Set hostname
  networking.hostName = "macvm-fs";

  # System state version
  system.stateVersion = 5;
}
