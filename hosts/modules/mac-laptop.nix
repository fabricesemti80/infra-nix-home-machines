{ pkgs, ... }: {

  homebrew = {
    # Homebrew package for laptop only!

    casks = [
      # Authentication & Security
      # "vmware-fusion"    # Virtualization platform
      "parallels" # Virtualization platform

    ];
  };

}