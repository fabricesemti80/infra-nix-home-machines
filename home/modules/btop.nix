# Module: Btop System Monitor
# Purpose: Configures btop++ system resource monitor with vim keybindings
# Platform: All
_: {
  # https://github.com/aristocratos/btop
  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };
  catppuccin.btop.enable = true;
}
