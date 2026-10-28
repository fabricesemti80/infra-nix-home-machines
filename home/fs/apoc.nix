{...}: {
  imports = [
    ../modules/home.nix
    ../profiles/test-vm.nix
    ../modules/plasma.nix
  ];

  programs.home-manager.enable = true; # https://nix-community.github.io/home-manager/

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
