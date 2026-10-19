{pkgs, ...}: {
  imports = [
    ./python.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    #* System Utilities & Core CLI
    btop # https://github.com/aristocratos/btop
    curl # https://curl.se/
    delta # https://github.com/dandavison/delta
    dig # https://www.isc.org/bind/
    docker-compose # https://github.com/docker/compose
    dust # https://github.com/bootandy/dust
    eza # https://github.com/eza-community/eza
    fd # https://github.com/sharkdp/fd
    git # https://git-scm.com/
    home-manager # https://nix-community.github.io/home-manager/
    jq # https://jqlang.github.io/jq/
    lazydocker # https://github.com/jesseduffield/lazydocker
    lazygit # https://github.com/jesseduffield/lazygit
    neovim # https://neovim.io/
    nh # https://github.com/nix-community/nh
    ripgrep # https://github.com/BurntSushi/ripgrep
    tailscale # https://tailscale.com
    tree # https://oldmanprogrammer.net/source.php?dir=projects/tree
    unzip # https://infozip.sourceforge.net/
    vim # https://www.vim.org/
  ];
}
