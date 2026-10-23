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
  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
    function wto --description 'Switch worktree and resume OMP'
      wt switch --execute='omp -c' $argv
    end
    function wton --description 'Create worktree and start OMP'
      if test (count $argv) -eq 0
        echo 'Usage: wton <branch> [-- prompt...]' >&2
        return 2
      end
      wt switch --create --execute=omp $argv
    end
  '';
}
