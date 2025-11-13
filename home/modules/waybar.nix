# Module: Waybar Status Bar
# Purpose: Configures Waybar status bar for Wayland compositors
# Platform: Linux (Wayland) only
_: let
  waybar_config = ./../../files/configs/waybar;
in {
  programs.waybar.enable = true;

  xdg.configFile.waybar = {
    recursive = true;
    source = "${waybar_config}";
  };
}
