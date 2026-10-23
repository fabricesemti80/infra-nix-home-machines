# Module: Oh My Pi (OMP)
# Purpose: Install OMP and manage user preferences declaratively.
# Platform: All (cross-platform)
{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};

  # Preserve the user's existing ~/.omp/agent/config.yml preferences.
  modelRoles = {
    default = "openai-codex/gpt-6-sol:low";
    smol = "@default";
    tiny = "opencode-go/mimo-v2.5:low";
    memory = "opencode-go/mimo-v2.5:low";
    task = "opencode-go/mimo-v2.5:medium";
    commit = "opencode-go/mimo-v2.5:low";
    vision = "opencode-go/mimo-v2.5:low";
    slow = "openai-codex/gpt-6.1-sol:high";
    plan = "@slow";
    advisor = "@slow";
    alternate = "openai-codex/gpt-6-luna:low";
  };

  ompConfig = {
    inherit modelRoles;

    symbolPreset = "nerd";
    composer.shape = "pi";
    theme.dark = "titanium";
    theme.light = "light";
    setupVersion = 2;
    dev.autoqaConsent = "denied";
    advisor.enabled = true;
    advisor.reviewMode = "agent-end";
    advisor.continueSeverity = "blocker";
    task.showResolvedModelBadge = true;
    prewalk.enabled = true;

    modelPresets."sol-default-economical" = {
      inherit modelRoles;
      defaultThinkingLevel = "high";
    };
  };
in {
  home.packages = [pkgs.omp];

  # Manage only config.yml; OMP's sessions, auth, and extensions remain runtime data.
  # force replaces the pre-existing user config with the equivalent declarative file.
  home.file.".omp/agent/config.yml" = {
    force = true;
    source = yamlFormat.generate "omp-agent-config.yml" ompConfig;
  };
}
