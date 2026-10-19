{...}: {
  imports = [
    ../modules/home.nix
    ../profiles/workstation.nix
    ../modules/plasma.nix
  ];

  programs.home-manager.enable = true; # https://nix-community.github.io/home-manager/

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
