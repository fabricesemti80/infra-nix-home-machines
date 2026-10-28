# Small interactive environment for graphical NixOS testing, not a workstation.
{pkgs, ...}: {
  imports = [
    ../modules/bat.nix
    ../modules/btop.nix
    ../modules/git.nix
    ../modules/ghostty.nix
    ../modules/zoxide.nix
  ];

  home.packages = with pkgs; [
    eza
    fd
    jq
    ripgrep
    unzip
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
  };

  # No workstation LSP/formatter bundle or Python/Ruby editor providers.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "macchiato";
    accent = "lavender";
  };
  nixpkgs.config.allowUnfree = true;
  home.enableNixpkgsReleaseCheck = false;
}
