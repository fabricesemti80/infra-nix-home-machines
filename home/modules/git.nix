{userConfig, ...}: {
  # Install git via home-manager module
  programs.git = {
    enable = true;
    signing.format = "ssh";
    
    settings = {
      user = {
        name = userConfig.fullName;
        email = userConfig.email;
        signingkey = "~/.ssh/id_gitsign_fs";
      };
      
      # Sign all commits using ssh key
      # https://jeppesen.io/git-commit-sign-nix-home-manager-ssh/
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      pull.rebase = "true";
    };
  };

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

  # New top-level Catppuccin configuration
  catppuccin.delta.enable = true;
}
