# Module: Btop System Monitor
# Purpose: Configures btop++ system resource monitor with vim keybindings
# Platform: All
_: {
  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };
  catppuccin.btop.enable = true;
}
