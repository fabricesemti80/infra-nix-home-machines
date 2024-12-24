{...}: {
  # Install bat via home-manager module
  programs.bat = {
    enable = true;
  };

  # New top-level Catppuccin configuration
  catppuccin.bat.enable = true;
}
