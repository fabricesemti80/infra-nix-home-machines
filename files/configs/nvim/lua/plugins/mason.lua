return {
  {
    "mason-org/mason.nvim",
    -- Disable Mason in favor of Nix packages
    enabled = false,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash-language-server",
        "black",
        "goimports",
        "golangci-lint",
        "hadolint",
        "isort",
        "json-lsp",
        "lua-language-server",
        "markdownlint",
        "prettier",
        "pyright",
        "shfmt",
        "stylua",
        "terraform-ls",
        "tflint",
        "yaml-language-server",
      })
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    -- Disable mason-lspconfig since Mason is disabled
    enabled = false,
  },
}
