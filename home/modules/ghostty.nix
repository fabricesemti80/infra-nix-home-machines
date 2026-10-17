{pkgs, ...}: {
  programs.ghostty = {
    enable = true;

    # macOS uses the Homebrew cask; let Nix manage the config only.
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then null
      else pkgs.ghostty;

    settings = {
      # https://ghostty-style.vercel.app/config/nocturnal-winter
      background = "#0d0d17";
      foreground = "#e6e5e5";
      cursor-color = "#e6e5e5";
      cursor-text = "#a6a6a6";

      selection-background = "#adbdd0";
      selection-foreground = "#000000";

      palette = [
        "0=#4d4d4d"
        "1=#f12d52"
        "2=#09cd7e"
        "3=#f5f17a"
        "4=#3182e0"
        "5=#ff2b6d"
        "6=#09c87a"
        "7=#fcfcfc"
        "8=#808080"
        "9=#f16d86"
        "10=#0ae78d"
        "11=#fffc67"
        "12=#6096ff"
        "13=#ff78a2"
        "14=#0ae78d"
        "15=#ffffff"
      ];
    };
  };
}
