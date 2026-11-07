# Package: Herdr Core
# Purpose: Persistent terminal runtime and `hc` CLI for Trinity
# Platform: x86_64-linux
{pkgs, ...}: let
  version = "0.1.18";
  herdr-core = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-core";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://releases.herdr.dev/core/${version}/herdr-core-linux-x86_64.tar.gz";
      sha256 = "5b2f97cb4b2a9d7a6b2cc5942628203ed9fbb7cc0c2b4b09ad8a6f5648e246b7";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      tar -xzf "$src" -C "$out/bin" herdr-core
      chmod +x "$out/bin/herdr-core"
      ln -s herdr-core "$out/bin/hc"
      runHook postInstall
    '';
    meta = {
      description = "Persistent terminal runtime for programs and coding agents";
      homepage = "https://herdr.dev/core/";
      license = pkgs.lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "hc";
    };
  };
in {
  environment.systemPackages = [herdr-core];
}
