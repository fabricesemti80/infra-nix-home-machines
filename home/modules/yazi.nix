# Module: Yazi terminal file manager
# Platform: macOS and Linux
{
  lib,
  pkgs,
  ...
}: {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

    # pkgs.yazi already wraps the preview/search dependencies from the guide.
    # Ghostty's image protocol is detected automatically; no terminal override.
    settings.opener.edit =
      [
        {
          run = ''nvim "$@"'';
          block = true;
          desc = "Neovim";
        }
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        {
          run = ''code --wait "$@"'';
          block = true;
          desc = "Visual Studio Code";
        }
      ];
  };
}
