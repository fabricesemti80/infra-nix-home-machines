# Module: Custom Scripts
# Purpose: Installs custom shell scripts to ~/.local/bin
# Platform: All
{
  pkgs,
  lib,
  ...
}: let
  scripts = ./../../files/scripts;
in {
  home.file.".local/bin" = {
    recursive = true;
    source = "${scripts}";
  };

  # Add to PATH on macOS (Linux adds ~/.local/bin automatically)
  home.sessionPath = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isDarwin ["$HOME/.local/bin"])
  ];
}
