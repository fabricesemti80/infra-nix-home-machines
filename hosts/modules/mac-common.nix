{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      #* Development Tools
      awscli2 # AWS Command Line Interface for managing AWS services
      delta # Enhanced git diff viewer with syntax highlighting
      direnv # Environment variable manager for project-specific environments
      hcp # HashiCorp Cloud Platform CLI for managing HashiCorp cloud resources
      lazydocker # Terminal UI for Docker management and monitoring
      packer # Infrastructure as code tool for image building
      pre-commit # Git pre-commit hook manager for code quality checks
      terraform # Infrastructure as code tool for infrastructure provisioning
      terraformer # Terraform state management tool for importing existing resources

      #* Language-Specific Tools
      (python3.withPackages (ps: with ps; [
        dnspython  # DNS toolkit for Python
        jmespath  # JSON query language for Python
        pip  # Python package installer
        virtualenv  # Python virtual environment creator
      ]))
      pipenv # Python dependency management tool

      #* System Utilities
      du-dust # Intuitive disk usage analyzer with visual output
      duf # Disk usage statistics utility with friendly UI
      home-manager # Nix user environment manager
      nh # Nix command wrapper and helper
      openconnect # VPN client compatible with Cisco AnyConnect
      sshpass # Non-interactive ssh password authentication
      tree # Directory structure viewer

      #* Modern CLI Replacements
      eza # Modern replacement for ls with more features
      fd # User-friendly alternative to find
      ripgrep # Fast alternative to grep with better syntax

      #* Task Runners and Processors
      go-task # Task runner for Go projects
      jq # Command-line JSON processor
      just # Modern command runner alternative to make
      yq # Command-line YAML processor

      #* Miscellaneous
      cmatrix # Terminal based "The Matrix" like animation
    ];
  };

  homebrew = {
    enable = true;

    # Homebrew Additional Repositories
    taps = [
      "nikitabobko/tap"
      "powershell/tap"
    ];

    brews = [
      #* Command Line Tools
      "ansible" # Configuration management tool
      "docker" # Containerization platform
      "docker-compose" # Multi-container Docker applications

      #* Coding Tools
      "hugo" # Static site generator
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
      "raycast" # Spotlight replacement and productivity tool
      "stats" # System monitoring menubar app

      #* Dev Tools
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
      "zen-browser" # Privacy-focused web browser

      #* Media
      "iina" # Modern media player for macOS

      #* Utilities
      "appcleaner" # Thorough app uninstaller
      "fliqlo" # Digital clock screensaver
      "hiddenbar" # Menu bar icon organization tool
      "numi" # Calculator and unit converter
      "shottr" # Screen capture and annotation tool
      "tailscale" # Zero trust VPN

      #* Fonts
      "font-hack-nerd-font" # Nerd font for programming
    ];

    onActivation.cleanup = "zap"; # Remove outdated versions and unused packages
  };
}
