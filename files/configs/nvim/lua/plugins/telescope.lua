return {
  "nvim-telescope/telescope.nvim", -- Use the full repository path
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim", -- FZF native dependency
      build = "make", -- Ensure the build step runs after installation
    },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        hidden = true,
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--column",
          "--hidden",
          "--line-number",
          "--no-heading",
          "--smart-case",
          "--unrestricted",
          "--with-filename",
        },
      },
    })

    -- Load extensions
    telescope.load_extension("fzf")
  end,
}
