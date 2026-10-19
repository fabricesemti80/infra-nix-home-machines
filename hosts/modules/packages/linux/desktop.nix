{pkgs, ...}: {
  imports = [
    ./common.nix
  ];

  environment.systemPackages = with pkgs; [
    ghostty # https://ghostty.org/
    vlc # https://www.videolan.org/vlc/
  ];
}
