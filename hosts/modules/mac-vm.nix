{ pkgs, ... }: {
  homebrew = {
    # Homebrew Additional Repositories
    taps = [
      "FelixKratz/formulae"
    ];

    casks = [
      # System Enhancement
      "lua"
      "switchaudio-osx"
      "nowplaying-cli"
      "sf-symbols"
      "font-sf-mono"
      "font-sf-pro"
    ];
  };

  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
  };
}