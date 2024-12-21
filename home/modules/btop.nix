{...}: {
  # Install btop via home-manager module
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  # New top-level Catppuccin configuration
  catppuccin.btop.enable = true;
}
