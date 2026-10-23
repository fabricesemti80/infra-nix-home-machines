# Local kubeconfig maintenance; no Kubernetes API calls.
{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "kubeconfig-helper";
      runtimeInputs = [pkgs.python3 pkgs.kubectl];
      text = ''
        exec python3 ${../../files/lib/kubeconfig_helper.py} "$@"
      '';
    })
  ];
  programs.zsh.shellAliases = {
    "k.importContext" = "kubeconfig-helper import";
    "k.deleteContext" = "kubeconfig-helper delete";
  };
}
