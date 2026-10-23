# FZF previews and clipboard integration — https://github.com/junegunn/fzf
{pkgs, ...}: let
  clipboard =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/usr/bin/pbcopy"
    else "${pkgs.wl-clipboard}/bin/wl-copy";
  preview = pkgs.writeShellScript "fzf-preview" ''
    if [ -d "$1" ]; then
      ${pkgs.eza}/bin/eza --tree --level=2 --color=always -- "$1"
    elif [ -f "$1" ]; then
      ${pkgs.bat}/bin/bat --color=always --style=numbers --line-range=:500 -- "$1"
    fi
  '';
in {
  programs.fzf = {
    enable = true;
    historyWidget.command = "";
    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --exclude .git";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude .git";
    defaultOptions = [
      "--bind '?:toggle-preview'"
      "--bind 'ctrl-a:select-all'"
      "--bind 'ctrl-e:execute(nvim -- {+})'"
      "--bind 'ctrl-y:execute-silent(printf \"%s\\n\" {+} | ${clipboard})'"
      "--height=40%"
      "--info=inline"
      "--layout=reverse"
      "--multi"
      "--preview '${preview} {}'"
      "--preview-window=:hidden"
    ];
  };
  catppuccin.fzf.enable = true;
  # Do not display environment-variable values: they may contain credentials.
  programs.zsh.initContent = ''
    _fzf_comprun() {
      local cmd="$1"
      shift
      case "$cmd" in
        export|unset) fzf --preview-window=hidden "$@" ;;
        ssh) fzf --preview '${pkgs.dnsutils}/bin/dig {}' "$@" ;;
        *) fzf --preview '${preview} {}' "$@" ;;
      esac
    }
  '';
}
