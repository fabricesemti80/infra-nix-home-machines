# Inspired by TechDufus/dotfiles; intentionally keep new sessions separate.
wto() {
  wt switch --execute='omp -c' "$@"
}
wton() {
  if (( $# == 0 )) || [[ "$1" == -- ]]; then
    print -u2 'Usage: wton <branch> [-- prompt...]'
    return 2
  fi
  wt switch --create --execute=omp "$@"
}
