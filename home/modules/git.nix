# Module: Git Version Control
# Purpose: Configures Git with SSH signing and Delta diff viewer
# Platform: All
{
  userConfig,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # ssh-keygen signs through $SSH_AUTH_SOCK, which is not the 1Password agent in every
  # macOS shell. Point it at the 1Password agent so the private key never sits on disk.
  # (1Password's own op-ssh-sign helper was tried and failed from a non-GUI shell.)
  # On Linux hosts the forwarded agent (~/.ssh/auth-sock) is already SSH_AUTH_SOCK.
  signWith1Password = pkgs.writeShellScript "git-ssh-sign-1password" ''
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    exec ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
in {
  # https://git-scm.com/
  programs.git = {
    enable = true;
    signing.format = "ssh";
    signing.signer = lib.mkIf isDarwin "${signWith1Password}";

    settings = {
      user = {
        inherit (userConfig) email;
        name = userConfig.fullName;
        # Public half only (written by ssh.nix); the private key lives in 1Password (item git-signing-fs).
        signingkey = "~/.ssh/id_gitsign_fs.pub";
      };

      # Sign all commits using SSH key
      # https://jeppesen.io/git-commit-sign-nix-home-manager-ssh/
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      pull.rebase = true;
      fetch.prune = true;
      rerere.enabled = true;
      diff.colorMoved = "zebra";
      init.defaultBranch = "main";
    };
  };

  # https://github.com/dandavison/delta
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      keep-plus-minus-markers = true;
      light = false;
      line-numbers = true;
      navigate = true;
      width = 280;
    };
  };

  catppuccin.delta.enable = true;
}
