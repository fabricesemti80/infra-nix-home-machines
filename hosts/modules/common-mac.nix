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
      du-dust # Disk usage analyzer
      eza # Modern ls replacement
      fd # Find alternative
      home-manager # User environment manager
      jq # JSON processor
      just # Command runner
      kubectl # Kubernetes CLI
      lazydocker # Docker TUI
      nh # Nix helper
      numi
      obsidian # Note-taking app
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
      # GUI applications to install via Homebrew
      "1password"
      "aerospace" # Window manager
      # "anki" # Flashcard app
      "brave-browser" # Web browser
      "obs" # Streaming software
      "raycast" # Spotlight replacement
    ];
    taps = [
      # Additional Homebrew repositories
      "nikitabobko/tap"
    ];
    onActivation.cleanup = "zap"; # Aggressive cleanup of unused packages
  };
}
