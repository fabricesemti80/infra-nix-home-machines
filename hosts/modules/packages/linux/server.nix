{pkgs, ...}: {
  imports = [
    ./common.nix
  ];

  # Server-specific system packages can be declared here
  environment.systemPackages = with pkgs; [
    # Currently inheriting all base utilities from common.nix
  ];
}
