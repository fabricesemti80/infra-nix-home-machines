{pkgs, ...}: {
  # System packages to install
  environment = {
    systemPackages = with pkgs; [
      (python3.withPackages (ps: with ps; [pip virtualenv])) # Python with common packages

      bartender # Menu bar organization
      cmatrix
      colima # Docker alternative for macOS
      delta # Better git diff
      docker # Container platform
      docker-compose # Docker compose
      du-dust # Disk usage analyzer
      duf # Disk usage analyzer
      eza # Modern ls replacement
      fd # Find alternative
      home-manager # User environment manager
      jq # JSON processor
      just # Command runner

      ## Kubernetes
      # kubectl # Kubernetes CLI

      lazydocker # Docker TUI
      nh # Nix helper
      numi
      openconnect # VPN client
      pipenv # Python environment manager
      ripgrep # Fast grep alternative
      tree
      vscode # Code editor
    ];
  };

  # Configure Homebrew
  homebrew = {
    enable = true;
    casks = [
      ## Security
      "1password"
      "1password-cli"

      ## Workflow
      "aerospace" # Window manager
      "bartender" # Menu bar customization
      "raycast" # Spotlight replacement
      "stats" # System monitor
      "vmware-fusion" # Virtualization

      ## Productivity & PKM
      "obsidian" # Note-taking app
      "anytype" # Note-taking app
      # "anki" # Flashcard app
      "capacities" # Note-taking app
      "notion" # Note-taking app

      ## Interwebs & communication
      "brave-browser" # Web browser
      "whatsapp"

      ##  DevOps
      "openlens"
      "orbstack" # Docker desktop alternative
      "wezterm" # Terminal emulator
      # "alacritty" # Terminal emulator

      ## Utilities
      "appcleaner" # Application uninstaller
      "karabiner-elements" # Keyboard customization
      "hyperkey" # Keyboard customization
      "little-snitch" # Firewall

    ];
    taps = [
      # Additional Homebrew repositories
      "nikitabobko/tap"
    ];
    onActivation.cleanup = "zap"; # Aggressive cleanup of unused packages
  };
}
