# Module: DockTail
# Purpose: Expose Docker containers as Tailscale services via labels.
# Platform: NixOS only. Requires Docker and a host Tailscale socket.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.containers.docktail;
in {
  options.my.containers.docktail = {
    enable = lib.mkEnableOption "DockTail container proxy";

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/docktail/env";
      description = ''
        Path to an environment file containing TAILSCALE_OAUTH_CLIENT_ID
        and TAILSCALE_OAUTH_CLIENT_SECRET. The justfile pushes this file
        from 1Password at deploy time.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.docktail = {
      image = "ghcr.io/marvinvr/docktail:latest";
      autoStart = true;
      environmentFiles = [cfg.environmentFile];
      environment = {
        LOG_LEVEL = "info";
        RECONCILE_INTERVAL = "60s";
        TAILSCALE_SOCKET = "/var/run/tailscale/tailscaled.sock";
        DELETE_UNUSED_SERVICES = "true";
      };
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "/var/run/tailscale:/var/run/tailscale"
      ];
    };

    # Ensure DockTail starts after Tailscale is up so the socket exists.
    systemd.services.docker-docktail = {
      after = ["tailscaled.service"];
      requires = ["tailscaled.service"];
    };
  };
}
