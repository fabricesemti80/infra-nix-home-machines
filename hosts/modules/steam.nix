# Module: Steam Gaming Platform
# Purpose: Configures Steam with remote play support
# Platform: NixOS only
_: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
}
