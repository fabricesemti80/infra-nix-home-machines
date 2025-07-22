{pkgs, ...}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Remove outdated versions and unused packages
      upgrade = true;
    };

    # Homebrew Additional Repositories
    taps = [
      "nikitabobko/tap"
      "powershell/tap"
    ];

    brews = [
      #* AI Tools
      "gemini-cli" # AI-powered command-line interface

      #* DevOps & Infrastructure
      # "ansible" # Configuration management tool
      # "docker" # Containerization platform
      "docker-compose" # Tool for defining and running multi-container Docker applications
      "opentofu" # Open-source infrastructure as code tool

      #* Development Tools (CLI)
      "hugo" # Fast static site generator
      "nodejs" # JavaScript runtime environment
      "ruff" # Extremely fast Python linter
    ];

    casks = [
      #* Authentication & Security
      "1password" # Secure password manager
      "1password-cli" # Command-line interface for 1Password

      #* Productivity & Utilities
      # "rectangle" # Window management for macOS
      # "notion" # All-in-one workspace for notes, tasks, and collaboration
      "capacities" # Connected knowledge management tool
      "fliqlo" # Digital clock screensaver
      "hiddenbar" # Menu bar icon organization tool
      # "keycastr" # Show keystrokes in the menu bar
      "numi" # Calculator and unit converter
      "shottr" # Feature-rich screenshot tool
      # "appcleaner" # Thorough app uninstaller
      # "tailscale" # Zero trust VPN #! installed from App Store

      #* Virtualization & Containers
      "orbstack" # Fast, lightweight Docker and Linux machine alternative
      "vagrant" # Tool for building and managing virtual machine environments
      "citrix-workspace" # Client for accessing virtual desktops and applications

      #* System Enhancements
      "aerospace" # Tiling window manager for macOS
      "commander-one" # Dual-pane file manager for macOS
      "raycast" # Powerful spotlight replacement and productivity launcher
      "stats" # System monitoring tool for macOS menubar

      #* Development Tools (GUI)
      "gcloud-cli" # Google Cloud SDK command-line tools
      "lm-studio" # Local AI model runner and chat interface
      "obsidian" # Powerful knowledge base and note-taking tool
      "powershell" # Cross-platform automation and configuration tool
      "termius" # Cross-platform SSH client and terminal
      "visual-studio-code" # Popular code editor
      "warp" # Modern terminal with AI features

      #* Browsers & Communication
      "vivaldi" # Feature-rich web browser with customization options
      "brave-browser" # Privacy-focused web browser with ad blocker
      "whatsapp" # Secure messaging application
      # "zen-browser" # Privacy-focused web browser

      #* Media Players
      "iina" # Modern media player for macOS

      #* Fonts
      "font-hack-nerd-font" # Developer-oriented font with glyphs for programming
    ];
  };
}
