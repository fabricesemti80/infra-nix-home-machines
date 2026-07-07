# Module: AI Tools
# Purpose: Per-user Claude Code, Codex, OpenCode, Antigravity and related AI tooling configuration
# Platform: All (cross-platform)
# Includes: token-saving ignore files, plugin auto-loading, shell aliases, litellm proxy
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${userConfig.name}"
    else "/home/${userConfig.name}";
in {
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
    # Caveman and ponytail are auto-loaded once installed (see ai-plugins-install alias).
    ".claude/settings.json" = {
      force = true;
      text = builtins.toJSON {
        enabledPlugins = {
          "warp@claude-code-warp" = true;
          "caveman@caveman" = true;
          "ponytail@ponytail" = true;
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
          "ponytail" = {
            source = {
              source = "github";
              repo = "DietrichGebert/ponytail";
            };
          };
        };
        env = {
          CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        };
      };
    };

    # OpenCode global config with plugins
    # ponytail and caveman are loaded from local plugin paths written by
    # ai-plugins-install (caveman installer + manual ponytail clone).
    ".config/opencode/opencode.jsonc" = {
      force = true;
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        plugin = [
          "${homeDir}/.config/opencode/plugins/ponytail/.opencode/plugins/ponytail.mjs"
          "${homeDir}/.config/opencode/plugins/caveman/plugin.js"
        ];
        agent = {
          explore.disable = true;
          general.disable = true;
        };
        shell = "zsh";
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

  # Claude Code keeps plugin metadata in settings.json and the `claude plugin install`
  # command needs to read/write it. Home-manager normally symlinks the file to the Nix
  # store (read-only), so copy it back to the home directory as a regular writable file
  # after activation. On each switch the content is reset to the Nix-defined config.
  home.activation.claudeWritableSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD rm -f $HOME/.claude/settings.json
    $DRY_RUN_CMD cp ${config.home.file.".claude/settings.json".source} $HOME/.claude/settings.json
    $DRY_RUN_CMD chmod 644 $HOME/.claude/settings.json
  '';

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

    # Ponytail helpers
    ponytail-install = "claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail";
    ponytail = "claude /ponytail";

    # One-shot install/update of caveman and ponytail across all mainstream AI tools.
    # Claude Code and OpenCode will auto-load them afterwards via settings.json/opencode.jsonc.
    # Codex requires enabling the plugin via its /plugins UI after the marketplace is added.
    ai-plugins-install = ''
            echo "==> Installing caveman for all detected agents..."
            curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash

            # The caveman installer writes its own ~/.config/opencode/opencode.json which conflicts
            # with our Nix-managed ~/.config/opencode/opencode.jsonc. Remove the stray file.
            if [ -f "$HOME/.config/opencode/opencode.json" ]; then
              rm -f "$HOME/.config/opencode/opencode.json"
            fi

            echo "==> Installing ponytail for Claude Code..."
            claude plugin marketplace add DietrichGebert/ponytail
            claude plugin install ponytail@ponytail || echo "ponytail Claude install skipped/failed"

            echo "==> Installing ponytail for Codex..."
            codex plugin marketplace add DietrichGebert/ponytail || echo "ponytail Codex marketplace add skipped/failed"
            # Codex has no CLI 'plugin install'; enable by appending to its config.toml.
            if [ -f "$HOME/.codex/config.toml" ] && ! grep -q '^\[plugins\."ponytail@ponytail"\]' "$HOME/.codex/config.toml"; then
              cat >> "$HOME/.codex/config.toml" <<'EOF'

      [plugins."ponytail@ponytail"]
      enabled = true
      EOF
            fi

            echo "==> Installing ponytail for OpenCode..."
            mkdir -p "$HOME/.config/opencode/plugins"
            rm -rf "$HOME/.config/opencode/plugins/ponytail"
            git clone --depth 1 https://github.com/DietrichGebert/ponytail.git "$HOME/.config/opencode/plugins/ponytail" || echo "ponytail OpenCode clone skipped/failed"

            echo "==> Installing ponytail for Antigravity/Gemini..."
            if command -v agy >/dev/null 2>&1; then
              agy plugin install https://github.com/DietrichGebert/ponytail || echo "ponytail Antigravity install skipped/failed"
            elif command -v gemini >/dev/null 2>&1; then
              gemini extensions install https://github.com/DietrichGebert/ponytail || echo "ponytail Gemini install skipped/failed"
            else
              echo "Antigravity/Gemini CLI not found, skipping"
            fi

            echo "==> Done. Restart Claude Code/Codex/OpenCode/Antigravity to pick up changes."
    '';

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
