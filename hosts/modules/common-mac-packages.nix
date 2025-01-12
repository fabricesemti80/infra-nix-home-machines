{ pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [
      # Development Tools
      delta          # Enhanced git diff viewer with syntax highlighting
      lazydocker    # Terminal UI for Docker management

      # Language-Specific Tools
      (python3.withPackages (ps: with ps; [pip virtualenv]))  # Python development environment
      pipenv        # Python dependency management tool

      # System Utilities
      du-dust       # Intuitive disk usage analyzer
      duf           # Disk usage statistics utility
      home-manager  # Nix user environment manager
      nh            # Nix command wrapper and helper
      openconnect   # VPN client compatible with Cisco AnyConnect
      tree          # Directory structure viewer

      # Modern CLI Replacements
      eza           # Modern replacement for ls
      fd            # User-friendly alternative to find
      ripgrep       # Fast alternative to grep

      # Task Runners and Processors
      jq            # Command-line JSON processor
      just          # Modern command runner alternative to make

      # Miscellaneous
      cmatrix       # Terminal based "The Matrix" like animation
    ];
  };
}