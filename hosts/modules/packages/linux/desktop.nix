{pkgs, ...}: {
  imports = [
    ./common.nix
  ];

  environment.systemPackages = with pkgs; [
    ghostty
    vlc
  ];
}
