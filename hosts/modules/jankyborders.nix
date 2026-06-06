# # ? https://git.kempkens.io/daniel/dotfiles/raw/commit/568727ed6f6ea3a993c5cffb5575993c25d5b7f8/system/darwin/jankyborders.nix
{
  pkgs,
  config,
  ...
}: let
  pkg = pkgs.jankyborders;

  borders-config = [
    "style=round"
    "active_color=0xeebd93f9"
    "inactive_color=0xeeabb2bf"
    "width=7.0"
    "blur_radius=15.0"
    "hidpi=on"
    "ax_focus=on"
  ];
in {
  environment.systemPackages = [pkg];

  launchd.user.agents.jankyborders = {
    serviceConfig = {
      ProgramArguments = ["${pkg}/bin/borders"] ++ borders-config;

      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      EnvironmentVariables = {
        PATH = "${pkg}/bin:${config.environment.systemPath}";
        LANG = "en_US.UTF-8";
      };
    };
  };
}
