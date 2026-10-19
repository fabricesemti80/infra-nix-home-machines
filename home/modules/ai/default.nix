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

  # Shared global instructions for all coding agents (Claude Code, Codex, OpenCode).
  # Single source: edit here, all three tools stay in sync declaratively.
  # Tool-specific content (e.g. caveman mode) is appended per-file below.
  sharedAgentInstructions = ''
    ## Knowledge base (permanent wiki)

    - Wiki root: `${homeDir}/Documents/repositories/documentation/obsidian-vaults/online-vault`
    - BEFORE answering preference-, person-, or domain-specific questions: search the wiki first (`rg -il "<topic>" wiki/`, then read the best matches). Do not infer personal facts when the wiki may hold them.
    - When working inside the vault, or reading/writing its notes: follow the vault's own `CLAUDE.md` and `.codex/references/ai-first-rules.md` (PARA layout, AI-first frontmatter, `## For future agent` preambles, wikilinks, dated/source-backed claims).
    - AFTER learning something durable about the user, their systems, or their preferences: offer to ingest it into the wiki per those rules (correct PARA folder, update `wiki/index.md`, append to `wiki/log.md`). Do not write without approval.
    - `raw/daily/` and `raw/from-the-internet/` are permanent and immutable — never move, edit, or delete their content. Attachments belong in vault-root `files/`.
  '';
in {
  imports = [./ignores.nix];

  home.packages = [
    pkgs.omp # Oh My Pi coding agent — https://omp.sh/
    (pkgs.writeShellApplication {
      name = "dsh";
      runtimeInputs = [pkgs.nodejs_22];
      text = ''
        exec corepack pnpm dlx @deepseek-ai/dsh@latest "$@"
      '';
    })
  ];

  # Token-saving ignore files — prevent AI from indexing build artifacts, caches, large binaries
  home.file = {
    # Shared global agent instructions (see sharedAgentInstructions above).
    # force: these replace any hand-edited copies on activation.
    ".codex/AGENTS.md" = {
      force = true;
      text = ''
        # Global Instructions

        ${sharedAgentInstructions}'';
    };

    ".claude/CLAUDE.md" = {
      force = true;
      text = ''
        # Global Instructions

        ${sharedAgentInstructions}'';
    };

    ".config/opencode/AGENTS.md" = {
      force = true;
      text = ''
        <!-- caveman-begin -->
        Respond terse like smart caveman. All technical substance stay. Only fluff die.

        Rules:
        - Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging
        - Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
        - Pattern: [thing] [action] [reason]. [next step].
        - Not: "Sure! I'd be happy to help you with that."
        - Yes: "Bug in auth middleware. Fix:"

        Switch level: /caveman lite|full|ultra|wenyan
        Stop: "stop caveman" or "normal mode"

        Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

        Boundaries: code/commits/PRs written normal.
        <!-- caveman-end -->

        ${sharedAgentInstructions}'';
    };

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
        mcp = {
          whatsapp = {
            type = "local";
            command = ["npx" "-y" "@kahflane/whatsapp-mcp"];
            enabled = true;
          };
        };
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

  programs.zsh.initContent = lib.optionalString pkgs.stdenv.isDarwin ''
    claude() {
      local lms="$HOME/.lmstudio/bin/lms"
      local model="google/gemma-4-26b-a4b-qat"

      if [[ ! -x "$lms" ]]; then
        print -u2 "LM Studio CLI is missing; open LM Studio once to install lms."
        return 1
      fi
      if ! "$lms" server status 2>&1 | grep -Fq "running on port 1234"; then
        "$lms" server start --port 1234 || return
      fi
      if ! "$lms" ps | grep -Fq "$model"; then
        "$lms" load "$model" --context-length 65536 --yes || return
      fi

      ANTHROPIC_BASE_URL=http://127.0.0.1:1234 \
        ANTHROPIC_AUTH_TOKEN=lmstudio \
        CLAUDE_CODE_ATTRIBUTION_HEADER=0 \
        CLAUDE_CODE_MAX_CONTEXT_TOKENS=65536 \
        command /opt/homebrew/bin/claude --model "$model" "$@"
    }
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

    # DeepSeek Harness
    dsh-web = "dsh web";

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

    claude-local = "claude";
  };
}
