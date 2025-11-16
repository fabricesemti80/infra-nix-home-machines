# Module: Cliphist Clipboard Manager
# Purpose: Configures cliphist clipboard history for Wayland
# Platform: Linux (Wayland) only
_: {
  services.cliphist = {
    enable = true;
    systemdTarget = "hyprland-session.target";
  };
}
