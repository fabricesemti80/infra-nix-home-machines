{
  inputs,
  pkgs,
  ...
}: let
  submarine = pkgs.stdenvNoCC.mkDerivation {
    pname = "submarine";
    version = "0.3.8";
    src = pkgs.fetchurl {
      url = "https://github.com/SinaXhpm/Submarine/releases/download/v0.3.8/Submarine-v0.3.8-macos-arm64.app.zip";
      hash = "sha256-nlGahdLXwILRHU2gvy1WJmV5Y9pgA0aiwOmms2qxruo=";
    };
    nativeBuildInputs = [pkgs.unzip]; # https://infozip.sourceforge.net/
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/Applications"
      unzip -q "$src" -d "$out/Applications"
    '';
  };
in {
  imports = [
    ./python.nix
  ];

  environment.systemPackages = with pkgs; [
    #* AI Tools
    antigravity-cli # AI-powered command-line interface — https://antigravity.google
    chatgpt # ChatGPT desktop app with Codex — https://openai.com/chatgpt/desktop/
    cliamp # Terminal music player inspired by Winamp — https://github.com/bjarneo/cliamp
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default # Terminal workspace for coding agents — https://herdr.dev/
    llmfit # https://github.com/AlexsJones/llmfit
    opencode # AI coding agent CLI — https://github.com/anomalyco/opencode
    # ollama # Local AI model manager and runner — https://github.com/ollama/ollama

    #* DevOps & Infrastructure
    ansible # IT automation and configuration management — https://www.ansible.com/
    awscli2 # AWS Command Line Interface — https://aws.amazon.com/cli/
    age # age encryption tool used by SOPS — https://age-encryption.org/
    argocd # Argo CD CLI — https://argo-cd.readthedocs.io/en/stable/
    cilium-cli # Cilium CLI — https://www.cilium.io/
    cloudflared # Cloudflare Tunnel client — https://www.cloudflare.com/products/tunnel
    docker-compose # Multi-container Docker application tool — https://github.com/docker/compose
    doppler # Doppler CLI for secrets management — https://doppler.com
    gh # GitHub CLI — https://cli.github.com/
    hcp # HashiCorp Cloud Platform CLI — https://github.com/hashicorp/hcp
    helmfile # Declarative Helm release orchestration — https://helmfile.readthedocs.io/
    kubernetes-helm # Kubernetes package manager — https://helm.sh/
    kubectl # Kubernetes command-line tool — https://github.com/kubernetes/kubectl
    kubectx # Switch between Kubernetes contexts — https://github.com/ahmetb/kubectx
    kubeconform # Kubernetes manifest validation — https://github.com/yannh/kubeconform/
    kustomize # Kubernetes manifest customization — https://kustomize.io/
    lazydocker # Terminal UI for Docker management — https://github.com/jesseduffield/lazydocker
    opentofu # Open-source infrastructure as code tool — https://opentofu.org/
    packer # Infrastructure as code tool for image building — https://www.packer.io
    talhelper # Talos cluster configuration helper — https://github.com/budimanjojo/talhelper
    talosctl # CLI for managing Talos Linux clusters — https://www.talos.dev/
    terraform # Infrastructure as code tool — https://www.terraform.io/

    #* Development Tools
    codex # OpenAI Codex CLI — https://github.com/openai/codex
    delta # Enhanced git diff viewer — https://github.com/dandavison/delta
    direnv # Environment variable manager — https://direnv.net
    cue # Data validation language — https://cuelang.org/
    gitleaks # Secret scanning — https://github.com/gitleaks/gitleaks
    glow # Markdown terminal viewer — https://github.com/charmbracelet/glow
    gnupg # GNU Privacy Guard — https://gnupg.org/
    hugo # Fast static site generator — https://gohugo.io
    prettier # Multi-language formatter — https://prettier.io/
    shellcheck # Shell script linting — https://www.shellcheck.net/
    shfmt # Shell script formatter — https://github.com/mvdan/sh
    tflint # Terraform/OpenTofu linting — https://github.com/terraform-linters/tflint
    tree-sitter # Parser generator for nvim-treesitter — https://github.com/tree-sitter/tree-sitter
    yamllint # YAML linting — https://yamllint.readthedocs.io/

    #* Networking
    doggo # DNS client — https://github.com/mr-karan/doggo
    lazyssh # Minimal SSH config tool — https://github.com/Adembc/lazyssh
    ngrok # Public tunnels for local services — https://ngrok.com/
    nmap # Network exploration tool — https://nmap.org/

    #* Language-Specific Tools
    bun # JavaScript runtime and package manager — https://bun.sh
    nodejs_24 # Node.js 24 LTS runtime — https://nodejs.org/
    pipenv # Python dependency management tool — https://github.com/pypa/pipenv
    ruff # Extremely fast Python linter — https://github.com/astral-sh/ruff
    uv # Fast Python package installer and resolver — https://github.com/astral-sh/uv

    #* System Utilities
    aerospace # Tiling window manager for macOS — https://github.com/nikitabobko/AeroSpace
    bashInteractive # Modern GNU Bash shell — https://www.gnu.org/software/bash/
    dust # Intuitive disk usage analyzer — https://github.com/bootandy/dust
    duf # Disk usage statistics utility — https://github.com/muesli/duf/
    home-manager # Nix user environment manager — https://nix-community.github.io/home-manager/
    nh # Nix command wrapper and helper — https://github.com/nix-community/nh
    mkpasswd # Generate hashed passwords — https://github.com/rfc1036/whois
    openconnect # VPN client — https://www.infradead.org/openconnect/
    pre-commit # Git hook framework — https://pre-commit.com/
    sshpass # Non-interactive SSH password auth — https://sourceforge.net/projects/sshpass/
    sops # Secrets management tool — https://getsops.io/
    submarine # SSH and SFTP client — https://github.com/SinaXhpm/Submarine
    tree # Directory structure viewer — https://oldmanprogrammer.net/source.php?dir=projects/tree

    #* Modern CLI Replacements
    eza # Modern replacement for ls — https://github.com/eza-community/eza
    fd # Friendly alternative to find — https://github.com/sharkdp/fd
    ripgrep # Fast alternative to grep — https://github.com/BurntSushi/ripgrep
    zoxide # Smarter cd command — https://github.com/ajeetdsouza/zoxide

    #* Task Runners and Processors
    go-task # Task runner for Go projects — https://taskfile.dev/
    jq # Command-line JSON processor — https://jqlang.github.io/jq/
    just # Modern command runner — https://github.com/casey/just
    yq # Command-line YAML processor — https://github.com/kislyuk/yq

    #* Miscellaneous
    cmatrix # Terminal Matrix animation — https://github.com/abishekvashok/cmatrix
  ];
}
