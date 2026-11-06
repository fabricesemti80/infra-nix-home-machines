{...}: {
  imports = [../modules/home.nix];

  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
