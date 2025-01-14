{ pkgs, lib, ... }: {
  homebrew = {
    taps = [
      "FelixKratz/formulae"
    ];

    brews = [
      "borders"
    ];
  };

  services.borders = let
    cfg = config.services.borders;
  in {
    enable = true;
    options = [
      "active_color=0xffe1e3e4"
      "inactive_color=0xff494d64"
      "width=5.0"
    ];
  };

  launchd.user.agents.borders = {
    serviceConfig = {
      ProgramArguments = [ "/usr/local/bin/borders" ] ++ config.services.borders.options;
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/borders.log";
      StandardErrorPath = "/tmp/borders.error.log";
    };
  };
}
