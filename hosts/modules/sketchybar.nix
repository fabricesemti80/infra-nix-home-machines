{ pkgs, ... }: {
  homebrew = {
    # Homebrew Additional Repositories
    taps = [
      "FelixKratz/formulae"
    ];

    brews = [
      "sketchybar"     # Customizable macOS menubar replacement
      "lua"
      "switchaudio-osx"
      "nowplaying-cli"
    ];

    casks = [
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
