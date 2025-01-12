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


  homebrew = {
    enable = true;

    # Homebrew package types:
    # - brews: Command line tools and libraries, installed from source/binary, located in /usr/local/Cellar
    # - casks: GUI applications with graphical interfaces, pre-built binaries, installed to /Applications

    # Homebrew Additional Repositories
    taps = [
      "nikitabobko/tap"
    ];

    # Command Line Tools (brews)
    brews = [
      "docker"          # Containerization platform
      "docker-compose"  # Multi-container Docker applications
    ];

    casks = [
      # Authentication & Security
      "1password"         # Password manager
      "1password-cli"     # 1Password command-line tool

      # System Enhancement
      "aerospace"         # Window manager for macOS
      # "hyperkey"         # Hyper key modifier functionality
      # "karabiner-elements" # Keyboard customization
      "raycast"          # Spotlight replacement and productivity tool
      "stats"            # System monitoring menubar app
      "sketchybar"     # Customizable macOS menubar replacement

      # Development Environment
      "openlens"         # Kubernetes IDE and management
      "orbstack"         # Lightweight Docker desktop alternative
      "visual-studio-code" # Modern code editor
      "wezterm"          # GPU-accelerated terminal emulator

      # Knowledge Management
      "anytype"          # Local-first note-taking system
      "capacities"       # Visual note-taking and organization
      "notion"           # All-in-one workspace
      "obsidian"         # Markdown knowledge base

      # Internet & Communication
      "brave-browser"    # Privacy-focused web browser
      "whatsapp"         # Messaging platform

      # Utilities
      "appcleaner"       # Thorough app uninstaller
      # "bartender"        # Menu bar icon organization
      "numi"           # Calculator and unit converter

      # Fonts
      "font-hack-nerd-font"  # Nerd font for programming

    ];

    onActivation.cleanup = "zap";  # Remove outdated versions and unused packages
  };

}