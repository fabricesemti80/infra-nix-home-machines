# Settings compatible with the Herdr v0.9.5 flake input — https://herdr.dev/
{pkgs, ...}: {
  home.packages = [pkgs.gh pkgs.gh-dash];
  xdg.configFile."herdr/config.toml" = {
    force = true;
    source = ../../files/configs/herdr.toml;
  };
}
