# Trinity container workloads
{...}: {
  imports = [
    ../modules/containers/docktail.nix
    ../modules/containers/portainer.nix
  ];

  my.containers.docktail.enable = true;
  my.containers.portainer.enable = true;
}
