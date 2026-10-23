# Kubernetes terminal UI — https://k9scli.io/
{pkgs, ...}: let
  helmValues = pkgs.writeShellScript "k9s-helm-values" ''
    set -euo pipefail
    ${pkgs.kubernetes-helm}/bin/helm get values "$1" \
      --namespace "$2" --kube-context "$3" | ${pkgs.less}/bin/less -K
  '';
in {
  # Home Manager installs pkgs.k9s when enabled, on both neo and apoc.
  programs.k9s = {
    enable = true;
    package = pkgs.k9s;
    settings.k9s.refreshRate = 2;
    plugins.helm-values = {
      shortCut = "v";
      confirm = false;
      description = "Helm release values";
      scopes = ["helm"];
      command = "${helmValues}";
      background = false;
      args = ["$COL-NAME" "$NAMESPACE" "$CONTEXT"];
    };
  };

  catppuccin.k9s.enable = true;
}
