# Module: Bottom System Monitor
# Purpose: Configures bottom (btm) system resource monitor
# Platform: All
_: {
  # https://clementtsang.github.io/bottom/
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        avg_cpu = true;
        temperature_type = "c";
      };
      colors.low_battery_color = "red";
    };
  };
}
