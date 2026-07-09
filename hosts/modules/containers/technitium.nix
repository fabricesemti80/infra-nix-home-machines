# Module: Technitium DNS Server
# Purpose: Recursive/authoritative DNS server with web console exposed via
#          DockTail. DNS queries are served on host port 53 UDP/TCP.
# Platform: NixOS only. Requires Docker.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.containers.technitium;
  hostname = config.networking.hostName;
in {
  options.my.containers.technitium = {
    enable = lib.mkEnableOption "Technitium DNS server";

    serviceName = lib.mkOption {
      type = lib.types.str;
      default = "technitium-${hostname}";
      description = ''
        Tailscale service name for the Technitium web console. Defaults to a
        per-host name to avoid collisions when running on multiple hosts.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/technitium";
      description = ''
        Path to the Technitium data directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.technitium = {
      image = "technitium/dns-server:latest";
      autoStart = true;
      ports = [
        "53:53/udp"
        "53:53/tcp"
      ];
      environment = {
        DNS_SERVER_DOMAIN = cfg.serviceName;
        DNS_SERVER_LOG_FOLDER_PATH = "/var/log/technitium/dns";
      };
      volumes = [
        "${cfg.dataDir}/config:/etc/dns"
        "${cfg.dataDir}/logs:/var/log/technitium/dns"
      ];
      labels = {
        "docktail.service.enable" = "true";
        "docktail.service.name" = cfg.serviceName;
        "docktail.service.port" = "5380";
        "docktail.service.service-port" = "443";
      };
      extraOptions = [
        "--cap-add=NET_BIND_SERVICE"
      ];
    };

    # Technitium needs the Docker network to be up so DockTail can proxy the web
    # console, but the DNS ports are bound directly to the host.
    systemd.services.docker-technitium = {
      after = ["docker-docktail.service"];
      wants = ["docker-docktail.service"];
    };
  };
}
