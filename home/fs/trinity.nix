{pkgs, ...}: {
  imports = [
    ../modules/home.nix
    ../profiles/terminal-workstation.nix
  ];

  # Native Linux CLIs; neo gets these from nix-darwin/Homebrew instead.
  home.packages = [pkgs.claude-code pkgs.codex];

  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
