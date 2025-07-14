{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      #* Development Tools
      ansible
      awscli2 # AWS Command Line Interface for managing AWS services
      delta # Enhanced git diff viewer with syntax highlighting
      direnv # Environment variable manager for project-specific environments
      hcp # HashiCorp Cloud Platform CLI for managing HashiCorp cloud resources
      lazydocker # Terminal UI for Docker management and monitoring
      packer # Infrastructure as code tool for image building
      pre-commit # Git pre-commit hook manager for code quality checks
      terraform # Infrastructure as code tool for infrastructure provisioning
      terraformer # Terraform state management tool for importing existing resources

      #* Networking
      doggo # DNS client

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
}
