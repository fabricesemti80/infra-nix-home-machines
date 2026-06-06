# Module: KDE Plasma Desktop
# Purpose: Enables SDDM display manager and KDE Plasma 6 desktop.
# Platform: NixOS only
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
in {
  options.kde = {
    enable = lib.mkEnableOption "KDE Plasma 6 desktop with SDDM display manager";
  };

  config = mkIf config.kde.enable {
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
  };
}
