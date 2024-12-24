{userConfig, ...}: {
  # Install git via home-manager module
  programs.git = {
    enable = true;
    userName = userConfig.fullName;
    userEmail = userConfig.email;
    #FIXME: need to repair signing key setup
    # signing = {
    #   key = userConfig.gitKey;
    #   signByDefault = true;
    # };
    
    delta = {
      enable = true;
      options = {
        keep-plus-minus-markers = true;
        light = false;
        line-numbers = true;
        navigate = true;
        width = 280;
      };
    };
    extraConfig = {
      pull.rebase = "true";
    };
  };

  # New top-level Catppuccin configuration
  catppuccin.delta.enable = true;
}
