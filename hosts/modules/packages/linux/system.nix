{pkgs, ...}: {
  imports = [
    ./python.nix
  ];

  environment.systemPackages = with pkgs; [
    #* System Utilities & Core CLI
    btop
    curl
    delta
    dig
    docker-compose
    dust
    eza
    fd
    git
    home-manager
    jq
    lazydocker
    lazygit
    neovim
    nh
    ripgrep
    tailscale
    tree
    unzip
    vim
  ];
}
