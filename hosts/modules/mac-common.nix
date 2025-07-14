{pkgs, ...}: {
  imports = [
    ./packages/system-packages.nix
    ./packages/homebrew-packages.nix
  ];
}
