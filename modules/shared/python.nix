{pkgs, ...}: let
  # ponytail: apply overrides to the interpreter's package set so they propagate
  # into python3.withPackages and every env package (not just litellm's deps).
  python3' = pkgs.python3.override {
    self = python3';
    packageOverrides = _final: prev: {
      # ponytail: langfuse pins wrapt < 2.0 but nixpkgs ships 2.2.2; relax until upstream catches up
      langfuse = prev.langfuse.overridePythonAttrs (old: {
        pythonRelaxDeps = ["wrapt"] ++ (old.pythonRelaxDeps or []);
      });
      # ponytail: pytest collection breaks on Python 3.14 deprecation warnings and
      # pythonImportsCheck tries to import pandas, which pandas-stubs does not propagate
      pandas-stubs = prev.pandas-stubs.overridePythonAttrs (_: {
        doCheck = false;
        pythonImportsCheck = [];
      });
      # ponytail: flaky timing test fails in sandbox
      opentelemetry-exporter-otlp-proto-grpc = prev.opentelemetry-exporter-otlp-proto-grpc.overridePythonAttrs (_: {
        doCheck = false;
        dontCheckRuntimeDeps = true;
      });
    };
  };

  pythonPackages = python3'.pkgs;

  litellmWithProxy = pythonPackages.litellm.overridePythonAttrs (old: {
    dependencies =
      old.dependencies
      ++ old.optional-dependencies.proxy
      ++ old.optional-dependencies.proxy-runtime;
  });

  pythonEnv = python3'.withPackages (ps:
    [
      litellmWithProxy # LiteLLM with proxy dependencies — https://docs.litellm.ai/
    ]
    ++ (with ps; [
      # Networking
      dnspython # DNS toolkit for Python — https://www.dnspython.org/

      # Data/Query
      jmespath # JSON query language for Python — https://github.com/jmespath/jmespath.py

      # Document conversion
      markitdown # Convert files and office documents to Markdown — https://github.com/microsoft/markitdown

      # Development
      pip # Python package installer — https://pip.pypa.io/
      virtualenv # Python virtual environment creator — https://virtualenv.pypa.io/
    ]));

  litellmProxy = pkgs.writeShellApplication {
    name = "litellm-proxy";
    runtimeInputs = [pythonEnv];
    text = ''exec python3 -m litellm.proxy.proxy_cli "$@"'';
  };
in {
  environment.systemPackages = [
    litellmProxy # Local CLI wrapper for LiteLLM — https://docs.litellm.ai/
    pythonEnv # Python environment with the packages listed above — https://www.python.org/
    pkgs.ffmpeg # Runtime dependency for markitdown audio conversion — https://ffmpeg.org/
  ];
}
