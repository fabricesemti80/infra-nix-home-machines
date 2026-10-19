# Module: Neovim Text Editor
# Purpose: Configures Neovim with LSP servers and development tools
# Platform: All
{pkgs, ...}: let
  neovim_config = ../../files/configs/nvim;
in {
  # https://neovim.io/
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped; # https://neovim.io/
    defaultEditor = true;
    withNodeJs = false; # Disabled due to build issues
    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      # Formatters
      alejandra # Nix — https://github.com/kamadorueda/alejandra
      black # Python — https://black.readthedocs.io/
      shfmt # Shell — https://github.com/mvdan/sh
      stylua # Lua — https://github.com/johnnymorganz/stylua

      # Linters
      golangci-lint # Go — https://golangci-lint.run/
      hadolint # Dockerfile — https://github.com/hadolint/hadolint
      markdownlint-cli # Markdown — https://github.com/igorshubovych/markdownlint-cli
      shellcheck # Shell — https://www.shellcheck.net/

      # Language Servers
      gopls # Go — https://github.com/golang/tools/tree/master/gopls
      lua-language-server # Lua — https://github.com/luals/lua-language-server
      nixd # Nix — https://github.com/nix-community/nixd
      bash-language-server # Bash — https://github.com/bash-lsp/bash-language-server
      pyright # Python — https://github.com/Microsoft/pyright
      terraform-ls # Terraform — https://github.com/hashicorp/terraform-ls
      vscode-langservers-extracted # HTML/CSS/JSON — https://github.com/hrsh7th/vscode-langservers-extracted
      yaml-language-server # YAML — https://github.com/redhat-developer/yaml-language-server

      # Tools
      gotools # Go tools — https://go.googlesource.com/tools
      isort # Python import sorter — https://pycqa.github.io/isort/
      prettier # Multi-language formatter — https://prettier.io/
      telescope # Gemini-protocol browser (not telescope.nvim) — https://telescope-browser.org/
      tflint # Terraform linter — https://github.com/terraform-linters/tflint
    ];
  };

  xdg.configFile.nvim = {
    source = "${neovim_config}";
    recursive = true;
  };
}
