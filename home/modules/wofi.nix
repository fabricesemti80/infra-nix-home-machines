# Module: Wofi Application Launcher
# Purpose: Configures wofi launcher for Wayland
# Platform: Linux (Wayland) only
_: {
  programs.wofi = {
    enable = true;
    settings = {
      insensitive = true;
      normal_window = true;
      prompt = "Search...";
      width = "50%";
      height = "40%";
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
  };
}
