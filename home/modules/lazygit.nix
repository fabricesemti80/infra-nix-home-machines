# Module: Lazygit
# Purpose: Configures lazygit terminal UI for git with delta integration
# Platform: All
_: {
  programs.lazygit = {
    enable = true;
    settings.git.paging = {
      colorArg = "always";
      pager = "delta --color-only --dark --paging=never";
    };
  };
}
