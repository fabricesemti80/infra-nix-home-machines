# OMP model setups share authentication, sessions, skills, and extensions.
# Use omp-codex / omp-opencode / omp-claude / omp-mixed to select a setup without editing runtime files.
{
  lib,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};

  profiles = {
    codex = {
      providers = ["openai-codex"];
      disabledProviders = ["opencode-go" "opencode"];
      modelRoles = {
        default = "openai-codex/gpt-6.1-sol:low";
        smol = "openai-codex/gpt-6-luna:low";
        tiny = "@smol";
        memory = "@smol";
        task = "openai-codex/gpt-6-luna:medium";
        commit = "@smol";
        vision = "@smol";
        widget = "@smol";
        slow = "openai-codex/gpt-6.1-sol:high";
        plan = "openai-codex/gpt-6-astra:high";
        advisor = "@slow";
        alternate = "@smol";
      };
    };
    opencode = {
      providers = ["opencode-go"];
      disabledProviders = ["openai-codex" "openai"];
      modelRoles = {
        default = "opencode-go/gpt-6-luna:medium";
        smol = "opencode-go/gpt-6-luna:low";
        tiny = "@smol";
        memory = "@smol";
        task = "opencode-go/gpt-6-luna:medium";
        commit = "opencode-go/gpt-6-luna:low";
        # gpt-6-luna accepts images; glm-5.3 and beam-free are text-only.
        vision = "opencode-go/gpt-6-luna:low";
        widget = "@smol";
        slow = "opencode-go/gpt-6-luna:high";
        plan = "opencode-go/glm-5.3:high";
        advisor = "@smol";
        alternate = "@smol";
      };
    };
    # Haiku for routine roles, Sonnet for work, Opus only for planning/review.
    claude = {
      providers = ["anthropic"];
      disabledProviders = ["openai-codex" "openai" "opencode-go" "opencode"];
      modelRoles = {
        default = "anthropic/claude-sonnet-5-5:low";
        smol = "anthropic/claude-haiku-5-5:low";
        tiny = "@smol";
        memory = "@smol";
        task = "anthropic/claude-sonnet-5-5:medium";
        commit = "@smol";
        vision = "@smol";
        widget = "@smol";
        slow = "anthropic/claude-opus-5-5:high";
        plan = "anthropic/claude-opus-5-5:high";
        advisor = "anthropic/claude-sonnet-5-5:low";
        alternate = "@smol";
      };
    };
    # Split recurring work across providers without using Opus for routine plans.
    # Keep Terra as driver/reviewer, Sonnet for implementation/planning, Haiku for helpers.
    mixed = {
      providers = ["openai-codex" "anthropic"];
      disabledProviders = ["openai" "opencode-go" "opencode"];
      modelRoles = {
        default = "openai-codex/gpt-6.1-terra:medium";
        smol = "anthropic/claude-haiku-5-5:low";
        tiny = "@smol";
        memory = "@smol";
        task = "anthropic/claude-sonnet-5-5:medium";
        commit = "@smol";
        vision = "openai-codex/gpt-6-luna:low";
        widget = "@smol";
        slow = "openai-codex/gpt-6.1-terra:high";
        plan = "anthropic/claude-sonnet-5-5:high";
        advisor = "@smol";
        alternate = "@smol";
      };
    };
  };

  commonConfig = {
    defaultThinkingLevel = "low";
    symbolPreset = "nerd";
    composer.shape = "pi";
    theme.dark = "titanium";
    theme.light = "light";
    setupVersion = 2;
    dev.autoqaConsent = "denied";
    advisor.enabled = true;
    advisor.reviewMode = "agent-end";
    advisor.continueSeverity = "blocker";
    task = {
      showResolvedModelBadge = true;
      # Route named agents through this setup's roles rather than personal pins.
      agentModelOverrides = {
        scout = "@smol";
        sonic = "@tiny";
        task = "@task";
        init = "@task";
        seance = "@task";
        reviewer = "@slow";
        security-reviewer = "@slow";
      };
    };
  };

  configFiles = builtins.mapAttrs (name: profile:
    yamlFormat.generate "omp-${name}.yml" (commonConfig
      // {
        inherit (profile) modelRoles disabledProviders;
        enabledProviders = profile.providers;
        # Mixed keeps its driver through implementation; cheap helpers are explicit.
        prewalk.enabled = name != "mixed";
      }))
  profiles;

  launchers = lib.mapAttrsToList (name: profile:
    pkgs.writeShellScriptBin "omp-${name}" ''
      exec ${pkgs.omp}/bin/omp \
        --config ${configFiles.${name}} \
        --model ${lib.escapeShellArg profile.modelRoles.default} \
        "$@"
    '')
  profiles;
in {
  home.packages = [pkgs.omp] ++ launchers;

  # Only preferences are managed. Credentials and conversation data stay writable.
  home.file = {
    ".omp/agent/config.yml" = {
      force = true;
      source = configFiles.codex;
    };
    ".omp/agent/model-configs/codex.yml".source = configFiles.codex;
    ".omp/agent/model-configs/opencode.yml".source = configFiles.opencode;
    ".omp/agent/model-configs/claude.yml".source = configFiles.claude;
    ".omp/agent/model-configs/mixed.yml".source = configFiles.mixed;
  };
}
