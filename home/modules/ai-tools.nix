# Module: AI Tools
# Purpose: Centralize Claude Code, Codex, and related AI tooling configuration
# Platform: All (cross-platform)
# Includes: token-saving ignore files, caveman install helper, shell aliases, litellm proxy
{...}: {
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

    # Claude Code settings with plugins
    ".claude/settings.json".text = builtins.toJSON {
      enabledPlugins = {
        "warp@claude-code-warp" = true;
        "caveman@caveman" = true;
      };
      extraKnownMarketplaces = {
        "claude-code-warp" = {
          source = {
            source = "github";
            repo = "warpdotdev/claude-code-warp";
          };
        };
        "caveman" = {
          source = {
            source = "github";
            repo = "JuliusBrussee/caveman";
          };
        };
      };
      env = {
        CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };

    # LiteLLM config for Claude Code → LM Studio translation
    "litellm_config.yaml".text = ''
      model_list:
        - model_name: gemma-local
          litellm_params:
            model: openai/google/gemma-4-26b-a4b-qat
            api_base: http://localhost:1234/v1
            api_key: lm-studio
    '';
  };

  # Additional token-saving environment variables
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

    # LiteLLM proxy management
    litellm-start = "litellm-proxy --config ~/litellm_config.yaml --host 127.0.0.1 --port 8888 > ~/litellm.log 2>&1 &";
    litellm-stop = "pkill -f 'litellm-proxy --config'";
    litellm-status = "curl -s http://localhost:8888/health || echo 'LiteLLM not running'";
    litellm-log = "tail -f ~/litellm.log";

    # Claude Code with local model (starts litellm if needed)
    claude-local = ''
      if ! curl -s http://localhost:8888/health > /dev/null 2>&1; then
        echo "Starting LiteLLM proxy..."
        litellm-proxy --config ~/litellm_config.yaml --host 127.0.0.1 --port 8888 > ~/litellm.log 2>&1 &
        sleep 3
      fi
      ANTHROPIC_BASE_URL="http://127.0.0.1:8888" ANTHROPIC_AUTH_TOKEN="sk-local-dummy-key" ANTHROPIC_MODEL="gemma-local" CLAUDE_CODE_MAX_OUTPUT_TOKENS="2048" claude --bare --model gemma-local
    '';
  };
}
