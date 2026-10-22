# Module: Home Directory Configuration
# Purpose: Sets up user home directory paths for cross-platform compatibility
# Platform: All
{
  pkgs,
  userConfig,
  ...
}: {
  home = {
    username = "${userConfig.name}";
    homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "/Users/${userConfig.name}"
      else "/home/${userConfig.name}";
  };
  home.packages = [pkgs.nix-output-monitor];
}
