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
      #* AI
      "gemini-cli" # AI-powered search engine

      #* Command Line Tools
      # "ansible" # Configuration management tool      "docker" # Containerization platform
      "docker-compose" # Multi-container Docker applications

      #* Coding Tools
      "hugo" # Static site generator
      "nodejs" # JavaScript runtime
      "ruff" # Fast Python linter
    ];

    casks = [

      #* Authentication & Security
      "1password" # Password manager
      "1password-cli" # 1Password command-line tool

      #* Work Tools
      "citrix-workspace" # Citrix Workspace client for remote applications

      #* System Enhancement
      "aerospace" # Window manager for macOS
      "commander-one" # Window manager for macOS
      "raycast" # Spotlight replacement and productivity tool
      "stats" # System monitoring menubar app

      #* Dev Tools
      # "docker-desktop" # Docker desktop for macOS
      "lm-studio" # Local AI model runner
      "obsidian" # Markdown knowledge base
      "orbstack" # Lightweight Docker desktop alternative
      "powershell" # Cross-platform automation and configuration tool
      "termius" # SSH session manager
      "vagrant" # Tool for building and managing virtual machine environments
      "visual-studio-code" # Modern code editor
      "warp" # Modern terminal with AI features

      #* Knowledge Management
      "notion" # All-in-one workspace for notes and collaboration

      #* Internet & Communication
      "brave-browser" # Privacy-focused web browser
      "whatsapp" # Messaging platform
      # "zen-browser" # Privacy-focused web browser

      #* Media
      "iina" # Modern media player for macOS

      #* Utilities
      # "appcleaner" # Thorough app uninstaller
      "fliqlo" # Digital clock screensaver
      "hiddenbar" # Menu bar icon organization tool
      "numi" # Calculator and unit converter
      "shottr" # Screen capture and annotation tool
      # "tailscale" # Zero trust VPNk #! installed from App Store
      #* Fonts
      "font-hack-nerd-font" # Nerd font for programming
    ];
  };
}
