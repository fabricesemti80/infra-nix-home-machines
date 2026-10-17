{...}: {
  imports = [
    ../modules/home.nix
    ../profiles/workstation.nix
    ../modules/plasma.nix
  ];

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
