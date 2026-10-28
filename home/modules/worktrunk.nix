# Declarative worktree workflow — https://worktrunk.dev/
{pkgs, ...}: {
  home.packages = [pkgs.worktrunk];
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "{{ repo_path }}/../.worktrees/{{ repo }}/{{ branch | sanitize }}"
  '';
  programs.zsh.initContent = ''
    eval "$(${pkgs.worktrunk}/bin/wt config shell init zsh)"
    source ${../../files/shell/worktrunk.zsh}
  '';
}
