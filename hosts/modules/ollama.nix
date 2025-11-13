# Module: Ollama AI Model Runner
# Purpose: Configures Ollama for running local AI models
# Platform: NixOS only
_: {
  services.ollama = {
    enable = true;
    # Uncomment for AMD GPU acceleration:
    # acceleration = "rocm";
  };
}
