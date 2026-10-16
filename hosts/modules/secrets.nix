# Shared system secret provisioning for nix-darwin and NixOS. Disabled until enrolled.
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  cfg = config.my.secrets;
  sshSecret = lib.types.submodule ({name, ...}: {
    options = {
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "Encrypted SOPS file containing this SSH identity.";
      };
      key = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "YAML key within the encrypted file.";
      };
    };
  });
in {
  options.my.secrets = {
    enable = lib.mkEnableOption "machine-local SOPS decryption with a dedicated age identity";
    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sops-nix/age-key.txt";
      description = "Absolute runtime path to the machine's private age identity, never a Nix path literal.";
    };
    sshKeys = lib.mkOption {
      type = lib.types.attrsOf sshSecret;
      default = {};
      description = "SSH private keys provisioned as /run/secrets/ssh-NAME, readable only by the configured user.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.ageKeyFile && !(lib.hasPrefix "/nix/store/" cfg.ageKeyFile);
        message = "my.secrets.ageKeyFile must be an absolute runtime path outside the Nix store.";
      }
      {
        assertion = lib.all (name: builtins.match "[a-zA-Z0-9_-]+" name != null) (builtins.attrNames cfg.sshKeys);
        message = "SSH identity names must contain only letters, digits, underscores or hyphens.";
      }
    ];
    sops.age = {
      keyFile = cfg.ageKeyFile;
      generateKey = false;
      sshKeyPaths = [];
    };
    sops.gnupg.sshKeyPaths = [];
    sops.secrets = lib.mapAttrs' (name: secret:
      lib.nameValuePair "ssh-${name}" {
        inherit (secret) sopsFile key;
        owner = userConfig.name;
        group =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "staff"
          else config.users.users.${userConfig.name}.group;
        mode = "0600";
      })
    cfg.sshKeys;
  };
}
