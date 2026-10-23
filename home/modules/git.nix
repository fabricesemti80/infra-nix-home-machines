# Module: Git Version Control
# Purpose: Configures Git with SSH signing and Delta diff viewer
# Platform: All
{userConfig, ...}: {
  # https://git-scm.com/
  programs.git = {
    enable = true;
    signing.format = "ssh";

    settings = {
      user = {
        inherit (userConfig) email;
        name = userConfig.fullName;
        signingkey = "~/.ssh/id_gitsign_fs";
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
