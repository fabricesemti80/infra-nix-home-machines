# Module: Portainer
# Purpose: Docker container management UI, exposed via DockTail.
# Platform: NixOS only. Requires Docker.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.containers.portainer;
in {
  options.my.containers.portainer = {
    enable = lib.mkEnableOption "Portainer container management UI";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/portainer-data";
      description = ''
        Path to the Portainer data directory. Mount this from a backup to
        preserve the admin password and existing configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.portainer = {
      image = "portainer/portainer-ce:latest";
      autoStart = true;
      volumes = [
        "${cfg.dataDir}:/data"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      labels = {
        "docktail.service.enable" = "true";
        "docktail.service.name" = "portainer";
        "docktail.service.port" = "9000";
        "docktail.service.service-port" = "443";
      };
    };
  };
}
