# Opt-in SSH management: no existing config or identity is replaced by default.
{
  config,
  lib,
  ...
}: let
  cfg = config.my.ssh;
in {
  options.my.ssh = {
    enable = lib.mkEnableOption "declarative SSH client configuration";
    importedConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Reviewed directory produced by tools/import-ssh-config.py; config is its entry point.";
    };
    secretIdentities = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {neo-auth = "/run/secrets/ssh-neo-auth";};
      description = "Runtime secret files exposed under ~/.ssh/sops/NAME. File contents never enter Nix.";
    };
    signingIdentity = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional secretIdentities entry used for Git SSH signing.";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Optional public keys for this user's incoming SSH access. Does not enable sshd or open a firewall.";
    };
    allowedSigners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Public SSH signing entries for ~/.ssh/allowed_signers; empty leaves the existing file alone.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.importedConfig == null || builtins.pathExists (cfg.importedConfig + "/config");
        message = "The imported SSH directory must contain a reviewed config file.";
      }
      {
        assertion = cfg.signingIdentity == null || builtins.hasAttr cfg.signingIdentity cfg.secretIdentities;
        message = "my.ssh.signingIdentity must name a declared secret identity.";
      }
      {
        assertion = lib.all (name:
          builtins.match "[a-zA-Z0-9_-]+" name
          != null
          && lib.hasPrefix "/" cfg.secretIdentities.${name}
          && !(lib.hasPrefix "/nix/store/" cfg.secretIdentities.${name})) (builtins.attrNames cfg.secretIdentities);
        message = "SSH identity names must be simple names and their sources must be absolute runtime paths outside the Nix store.";
      }
    ];
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = lib.optional (cfg.importedConfig != null) "~/.ssh/config.d/nix-imported/config";
    };
    home.file = lib.mkMerge [
      (lib.optionalAttrs (cfg.importedConfig != null) {
        ".ssh/config.d/nix-imported" = {
          source = cfg.importedConfig;
          recursive = true;
        };
      })
      (lib.mapAttrs' (name: path:
        lib.nameValuePair ".ssh/sops/${name}" {
          source = config.lib.file.mkOutOfStoreSymlink path;
        })
      cfg.secretIdentities)
      (lib.optionalAttrs (cfg.authorizedKeys != []) {
        ".ssh/authorized_keys".text = lib.concatStringsSep "\n" cfg.authorizedKeys + "\n";
      })
      (lib.optionalAttrs (cfg.allowedSigners != []) {
        ".ssh/allowed_signers".text = lib.concatStringsSep "\n" cfg.allowedSigners + "\n";
      })
    ];
    programs.git.settings.user.signingkey =
      lib.mkIf (cfg.signingIdentity != null)
      (lib.mkForce "${config.home.homeDirectory}/.ssh/sops/${cfg.signingIdentity}");
  };
}
