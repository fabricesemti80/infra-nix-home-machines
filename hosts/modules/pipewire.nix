# Module: PipeWire Audio
# Purpose: Enables the PipeWire audio stack with ALSA + PulseAudio bridges.
# Platform: NixOS only
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
in {
  options.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio stack (ALSA + PulseAudio)";
  };

  config = mkIf config.pipewire.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
