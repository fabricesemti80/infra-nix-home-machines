# Module: Tailscale subnet router / exit node
# Purpose: Declarative Tailscale setup for NixOS hosts that advertise routes,
#          act as exit nodes, and optionally enable Tailscale SSH.
# Platform: NixOS only
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.tailscale-router;
in {
  options.tailscale-router = {
    enable = lib.mkEnableOption "Tailscale subnet router / exit node";

    authKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/tailscale/tailscale-authkey";
      description = ''
        Path to a file containing the Tailscale auth key.
        The file is read by the tailscaled-autoconnect service.
      '';
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10.0.0.0/16" "192.168.0.0/16"];
      description = "Subnets to advertise to the Tailnet.";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise this host as a Tailscale exit node.";
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Tailscale SSH.";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["tag:server"];
      description = "Tailscale ACL tags to apply to this node.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = cfg.authKeyFile;
      openFirewall = true;
      useRoutingFeatures = "server";
      extraUpFlags =
        ["--reset" "--operator=root"]
        ++ lib.optional cfg.ssh "--ssh"
        ++ lib.optional cfg.advertiseExitNode "--advertise-exit-node"
        ++ lib.optionals (cfg.advertiseRoutes != []) [
          "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
        ]
        ++ lib.optionals (cfg.tags != []) [
          "--advertise-tags=${lib.concatStringsSep "," cfg.tags}"
        ];
    };

    networking.firewall = {
      trustedInterfaces = [config.services.tailscale.interfaceName];
      checkReversePath = lib.mkDefault "loose";
    };
  };
}
