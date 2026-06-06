# Module: Go Programming Language
# Purpose: Configures Go development environment with proper paths
# Platform: All
_: {
  programs.go = {
    enable = true;
    goBin = "go/bin";
    goPath = "go";
  };

  home.sessionPath = ["$HOME/go/bin"];
}
