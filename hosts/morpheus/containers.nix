# Morpheus container workloads
# Add host-specific containers here; none enabled yet.
{...}: {
  imports = [
    ../modules/containers/docktail.nix
    ../modules/containers/portainer.nix
  ];

  # my.containers.docktail.enable = true;
  # my.containers.portainer.enable = true;
}
