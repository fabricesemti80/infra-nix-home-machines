{pkgs, ...}: let
  # ponytail: flaky timing test fails in sandbox
  pythonPackages = pkgs.python3Packages.overrideScope (final: prev: {
    opentelemetry-exporter-otlp-proto-grpc = prev.opentelemetry-exporter-otlp-proto-grpc.overridePythonAttrs (_: {
      doCheck = false;
      dontCheckRuntimeDeps = true;
    });
  });

  litellmWithProxy = pythonPackages.litellm.overridePythonAttrs (old: {
    dependencies =
      old.dependencies
      ++ old.optional-dependencies.proxy
      ++ old.optional-dependencies.proxy-runtime;
  });

  pythonEnv = pkgs.python3.withPackages (ps:
    [
      litellmWithProxy
    ]
    ++ (with ps; [
      # Networking
      dnspython # DNS toolkit for Python

      # Data/Query
      jmespath # JSON query language for Python

      # Document conversion
      markitdown # Convert files and office documents to Markdown

      # Development
      pip # Python package installer
      virtualenv # Python virtual environment creator
    ]));

  litellmProxy = pkgs.writeShellApplication {
    name = "litellm-proxy";
    runtimeInputs = [pythonEnv];
    text = ''exec python3 -m litellm.proxy.proxy_cli "$@"'';
  };
in {
  environment.systemPackages = [
    litellmProxy
    pythonEnv
    pkgs.ffmpeg # Runtime dependency for markitdown audio conversion
  ];
}
