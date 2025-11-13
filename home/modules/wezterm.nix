_: {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require('wezterm')
      local config = wezterm.config_builder()

      config.term = 'xterm-256color'
      config.default_prog = { '/bin/zsh', '-l', '-c', 'tmux attach || tmux' }

      config.window_decorations = "RESIZE"
      config.enable_tab_bar = false
      config.initial_cols = 170
      config.initial_rows = 45
      config.window_padding = {
        left = 5,
        right = 5,
        top = 1,
        bottom = 1,
      }

      config.scrollback_lines = 10000

      config.font = wezterm.font_with_fallback({
        {
          family = 'MesloLGS Nerd Font',
          weight = 'Regular',
        },
      })

      if wezterm.target_triple == "x86_64-apple-darwin" then
        config.font_size = 15
      else
        config.font_size = 12
      end

      config.selection_word_boundary = ' \t\n{}[]()\"\'`,;:'
      -- Clipboard is enabled by default in WezTerm
      config.color_scheme = 'Catppuccin Macchiato'

      return config
    '';
  };
}
