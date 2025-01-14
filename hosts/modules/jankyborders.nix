{ pkgs, ... }: {

  homebrew = {

    # Homebrew package types:
    # - brews: Command line tools and libraries, installed from source/binary, located in /usr/local/Cellar
    # - casks: GUI applications with graphical interfaces, pre-built binaries, installed to /Applications

    # Homebrew Additional Repositories
    taps = [
      "FelixKratz/formulae"
    ];

    brews = [
      "borders"          # Highlight borders - https://github.com/FelixKratz/JankyBorders?tab=readme-ov-file#jankyborders
    ];

    # Enable the borders service
    services.borders = {
      enable = true;
      options = [
        "active_color=0xffe1e3e4"
        "inactive_color=0xff494d64"
        "width=5.0"
      ];
    };

  };

}
