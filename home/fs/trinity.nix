{pkgs, ...}: {
  imports = [
    ../modules/home.nix
    ../profiles/terminal-workstation.nix
  ];

  # Native Linux CLIs; neo gets these from nix-darwin/Homebrew instead.
  # Includes tools referenced by aliases in home/modules/zsh.nix (ls/ll/la/lt, ld, k*).
  home.packages = with pkgs; [
    claude-code
    codex
    eza
    kubectl
    lazydocker
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
