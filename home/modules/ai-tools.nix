# Module: AI Tools
# Purpose: Centralize Claude Code, Codex, and related AI tooling configuration
# Platform: All (cross-platform)
# Includes: token-saving ignore files, caveman install helper, shell aliases
_: {
  # Token-saving ignore files — prevent AI from indexing build artifacts, caches, large binaries
  home.file = {
    ".claudeignore".text = ''
      # Build artifacts
      node_modules/
      dist/
      build/
      target/
      .next/
      out/
      .output/
      .vercel/
      .turbo/
      .cache/
      __pycache__/
      .pytest_cache/
      .mypy_cache/
      .ruff_cache/
      .tox/
      .venv/
      .direnv/
      .devenv/
      coverage/
      .coverage
      htmlcov/
      .nyc_output/

      # Lock files (usually too large/noisy for context)
      package-lock.json
      yarn.lock
      pnpm-lock.yaml
      bun.lockb
      Cargo.lock
      poetry.lock
      Gemfile.lock

      # Logs & temp
      *.log
      *.tmp
      *.temp
      *.swp
      *.swo
      .DS_Store
      Thumbs.db

      # IDE / editor
      .vscode/
      .idea/
      *.code-workspace
      .zed/
      .nova/
      .vim/
      .nvim/

      # Nix
      result
      result-*/
      .nix-search/
      .direnv/

      # Terraform / Infra
      .terraform/
      *.tfstate
      *.tfstate.*
      .terraform.lock.hcl
      .terragrunt-cache/

      # Media / binaries
      *.png
      *.jpg
      *.jpeg
      *.gif
      *.ico
      *.svg
      *.mp4
      *.mov
      *.avi
      *.mp3
      *.wav
      *.qcow2
      *.iso
      *.img
      *.dmg
      *.pkg
      *.deb
      *.rpm
      *.zip
      *.tar.gz
      *.tar.bz2

      # Git
      .git/
      .gitignore

      # Documentation
      *.md
      *.rst
      *.txt
      CHANGELOG*
      LICENSE*
      LICENSE.*
      COPYING*
      AUTHORS*
      CONTRIBUTORS*

      # Secrets
      .env
      .env.*
      *.pem
      *.key
      *.crt
      *.p12
      *.pfx
      secrets/
      secrets.*
      .secrets/
    '';

    ".codexignore".text = ''
      node_modules/
      dist/
      build/
      .git/
      .cache/
      __pycache__/
      .venv/
      *.lock
      *.log
      *.png
      *.jpg
      *.svg
      result
      .direnv/
    '';
  };

  # Token-saving environment variable for Claude Code
  home.sessionVariables = {
    # Claude Code: disable auto-execution to save tokens on wrong guesses
    CLAUDE_CODE_SKIP_PERMISSIONS = "1";
    # Claude Code: prefer compact mode
    CLAUDE_CODE_COMPACT = "1";
  };

  # Shell aliases for quick AI tool access
  programs.zsh.shellAliases = {
    # Claude Code
    c = "claude";
    cc = "claude --continue";
    cq = "claude --quick";

    # Codex
    cx = "codex";
    cxq = "codex --quick";

    # AI file search (token-aware)
    aif = "find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.cache/*' | head -50";

    # Caveman helpers
    caveman-install = "claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman && npx skills add JuliusBrussee/caveman -a codex";
    caveman-stats = "claude /caveman-stats";
  };
}
