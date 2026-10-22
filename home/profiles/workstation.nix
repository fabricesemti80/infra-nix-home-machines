# Module: Common Home Configuration
# Purpose: Base configuration imported by all user home configurations
# Platform: All
{outputs, ...}: {
  imports = [
    # ../modules/aider.nix
    ../modules/ai-tools.nix
    ../modules/amp.nix
    ../modules/atuin.nix
    ../modules/bat.nix
    ../modules/btop.nix
    ../modules/fastfetch.nix
    ../modules/fish.nix
    ../modules/fuelcheck.nix
    ../modules/fzf.nix
    ../modules/ghostty.nix
    ../modules/git.nix
    ../modules/lazygit.nix
    ../modules/neovim.nix
    ../modules/scripts.nix
    ../modules/starship.nix
    ../modules/tmux.nix
    ../modules/zoxide.nix
    ../modules/zsh.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.fish-no-tests
      outputs.overlays.direnv-no-tests
      outputs.overlays.atuin-no-tests
      outputs.overlays.omp-herdr-fix
    ];
    config.allowUnfree = true;
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "macchiato";
    accent = "lavender";
  };

  # Disable version mismatch warning since we intentionally use unstable branches
  home.enableNixpkgsReleaseCheck = false;
}
