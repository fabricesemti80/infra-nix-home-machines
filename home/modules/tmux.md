# Tmux Configuration

This document provides an overview of the Tmux configuration defined in the `tmux.nix` file.

## Tmux Settings

- **Enable Tmux**: `true`
- **Base Index**: `1`
- **Escape Time**: `10` milliseconds
- **History Limit**: `10000` lines
- **Key Mode**: `vi`
- **Mouse Support**: `true`
- **Terminal Type**: `screen-256color`

### Custom Key Bindings and Configurations

- **Prefix Key**: 
  - Set prefix to `Ctrl + q`
  - Unbind `Ctrl + b`
- **Window Splitting**:
  - Vertical Split: `v`
  - Horizontal Split: `s`
- **Pane Resizing**:
  - Resize Down: `Shift + Down`
  - Resize Up: `Shift + Up`
  - Resize Left: `Shift + Left`
  - Resize Right: `Shift + Right`
- **Window Renaming**: `r`
- **Reload Configuration**: `R`
- **Clear Screen**: `Ctrl + l`
- **Project Selector**: `Ctrl + f`
- **Terminal Overrides**: `xterm-256color:RGB:smcup@:rmcup@`
- **Focus Events**: `on`
- **Escape Time**: `10` milliseconds
- **Vim Integration**: Smart pane switching with Vim awareness

## Catppuccin Theme Settings

- **Enable Catppuccin Theme**: `true`
- **Flavor**: `macchiato`
- **Status Background**: `none`
- **Window Number Color**: `@thm_peach`
- **Window Text**: `#W`
- **Window Text Color**: `@thm_bg`
- **Window Number Color**: `@thm_blue`
- **Window Text Color**: `@thm_surface_0`
- **Status Left Separator**: `█`
- **Status Right**: `@catppuccin_status_host @catppuccin_status_date_time`
- **Status Left**: `""`
