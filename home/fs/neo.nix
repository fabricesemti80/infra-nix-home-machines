{pkgs, ...}: {
  imports = [
    ../modules/home.nix
    ../profiles/workstation.nix
    ../modules/darwin-aerospace.nix
    ../modules/raycast.nix
  ];

  # Google Cloud CLI and scoped OAuth tooling for API access.
  home.packages = [pkgs.google-cloud-sdk pkgs.oauth2l];

  # Enable home-manager
  programs.home-manager.enable = true; # https://nix-community.github.io/home-manager/

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/opt/homebrew/bin/"
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
