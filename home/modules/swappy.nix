# Module: Swappy Screenshot Editor
# Purpose: Configures swappy screenshot annotation tool for Wayland
# Platform: Linux (Wayland) only
_: {
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=$HOME/Pictures
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png
  '';
}
