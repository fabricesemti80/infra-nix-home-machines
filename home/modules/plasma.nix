{
  config,
  pkgs,
  ...
}: let
  wallpaper = ../../files/wallpapers/wallpaper.jpg;
  applyWallpaper = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage";
  kwriteconfig = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
in {
  # Plasma session lockscreen background.
  xdg.configFile."kscreenlockerrc".text = ''
    [Greeter]
    WallpaperPlugin=org.kde.image

    [Greeter][Wallpaper][org.kde.image][General]
    Image=${wallpaper}
  '';

  # Write the desktop wallpaper into Plasma's config so it persists across
  # logins, and apply it live when a graphical session is active.
  home.activation.apocWallpaper = config.lib.dag.entryAfter ["writeBoundary"] ''
    cfg="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    desktop=$(
      ${pkgs.gawk}/bin/awk -F'[][]' '
        /^\[Containments\]\[[0-9]+\]$/ {id=$4}
        /^plugin=org.kde.plasma.folder$/ && id {print id; exit}
      ' "$cfg" 2>/dev/null || true
    )
    desktop=''${desktop:-1}

    ${kwriteconfig} --file "$cfg" \
      --group Containments --group "$desktop" \
      --key wallpaperplugin org.kde.image
    ${kwriteconfig} --file "$cfg" \
      --group Containments --group "$desktop" \
      --group Wallpaper --group org.kde.image --group General \
      --key Image ${wallpaper}

    if [ -n "''${DISPLAY:-}" ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      ${applyWallpaper} ${wallpaper} >/dev/null 2>&1 || true
    fi
  '';
}
