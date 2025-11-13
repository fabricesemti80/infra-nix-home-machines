# Module: Pop Shell GNOME Extension
# Purpose: Configures Pop Shell tiling window manager for GNOME
# Platform: Linux (GNOME) only
_: {
  xdg.configFile."pop-shell/config.json".text = ''
    {
      "float": [
        {
          "class": "ulauncher"
        },
        {
          "class": "org.gnome.Calculator"
        }
      ],
      "skiptaskbarhidden": [],
      "log_on_focus": false
    }
  '';
}
