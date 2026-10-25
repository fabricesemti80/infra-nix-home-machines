# Shared Agent Skill; keep references, assets, and scripts together.
{
  lib,
  pkgs,
  ...
}: let
  source = pkgs.fetchFromGitHub {
    owner = "cathrynlavery";
    repo = "diagram-design";
    rev = "0b9b10cab3dbf695642fa1a6c4b4f60df9083689"; # 2.6.120
    hash = "sha256-Kt1kWXvWSRi/rA628LS3YtCpFEysR/LKmK6urpVlxOg=";
  };
  roots = [
    ".agents/skills" # Codex and other Agent Skills hosts.
    ".claude/skills"
    ".omp/agent/skills"
    ".config/opencode/skills"
  ];
in {
  home.file = lib.genAttrs (map (root: "${root}/diagram-design") roots) (_: {
    source = "${source}/skills/diagram-design";
  });
}
