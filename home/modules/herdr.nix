# Settings compatible with the Herdr v0.9.5 flake input — https://herdr.dev/
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  herdr = "${inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/herdr";

  # Diff-review pane for agent changes — https://github.com/persiyanov/herdr-reviewr
  # Bump the tag here; activation replaces a plugin installed at a different ref.
  reviewrRef = "v0.49.1";
in {
  home.packages =
    [pkgs.gh pkgs.gh-dash]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default];
  xdg.configFile."herdr/config.toml" = {
    force = true;
    source = ../../files/configs/herdr.toml;
  };

  # Match Herdr's dracula theme (the plugin defaults to catppuccin).
  xdg.configFile."herdr/plugins/config/persiyanov.reviewr/config.toml".text = ''
    theme = "dracula"
  '';

  # Plugins are installed by `herdr plugin` into ~/.config/herdr, so activation
  # reconciles them idempotently. The install step downloads the release binary
  # and verifies its published checksum. A failed fetch only warns.
  home.activation.herdrReviewr = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="${lib.makeBinPath [pkgs.curl pkgs.git pkgs.coreutils pkgs.gnugrep]}:$PATH"
    if ! ${herdr} plugin list 2>/dev/null | grep -qF '[github:persiyanov/herdr-reviewr@${reviewrRef}]'; then
      if ${herdr} plugin list 2>/dev/null | grep -qF 'persiyanov.reviewr'; then
        $DRY_RUN_CMD ${herdr} plugin uninstall persiyanov.reviewr \
          || echo "warning: herdr plugin persiyanov.reviewr was not removed" >&2
      fi
      $DRY_RUN_CMD timeout 180 ${herdr} plugin install persiyanov/herdr-reviewr --ref ${reviewrRef} --yes \
        || echo "warning: herdr plugin persiyanov.reviewr was not installed" >&2
    fi
  '';
}
