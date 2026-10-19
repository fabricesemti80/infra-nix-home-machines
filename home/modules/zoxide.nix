# Module: Zoxide
# Purpose: Configures zoxide for smarter cd command
# Platform: All
_: {
  # https://github.com/ajeetdsouza/zoxide
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
