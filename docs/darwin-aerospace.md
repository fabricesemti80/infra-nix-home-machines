
# Darwin Aerospace Configuration

This document provides an overview of the AeroSpace configuration defined in the `darwin-aerospace.nix` file.

## AeroSpace Settings

- **Start at Login**: `true`
- **Normalization Settings**:
  - Flatten Containers: `true`
  - Opposite Orientation for Nested Containers: `true`
- **Accordion Layout Settings**:
  - Padding: `30`
- **Default Root Container Settings**:
  - Layout: `tiles`
  - Orientation: `auto`
- **Mouse Follows Focus Settings**:
  - On Focused Monitor Changed: `move-mouse monitor-lazy-center`
  - On Focus Changed: `move-mouse window-lazy-center`
- **Automatically Unhide macOS Hidden Apps**: `true`
- **Key Mapping Preset**: `qwerty`

## Gaps Settings

- **Inner Gaps**:
  - Horizontal: `6`
  - Vertical: `6`
- **Outer Gaps**:
  - Left: `6`
  - Bottom: `6`
  - Top: `6`
  - Right: `6`

## Main Mode Bindings

- **Window Management**:
  - Close Window: `alt-q`
  - Layout Tiles: `alt-/`
  - Layout Accordion: `alt-,`
  - Fullscreen: `alt-m`
- **Focus Movement**:
  - Focus Left: `alt-h`
  - Focus Down: `alt-j`
  - Focus Up: `alt-k`
  - Focus Right: `alt-l`
- **Window Movement**:
  - Move Left: `alt-shift-h`
  - Move Down: `alt-shift-j`
  - Move Up: `alt-shift-k`
  - Move Right: `alt-shift-l`
- **Resize Windows**:
  - Resize Decrease: `alt-shift--`
  - Resize Increase: `alt-shift-=`
- **Workspace Management**:
  - Workspace 1: `alt-1`
  - Workspace 2: `alt-2`
  - Workspace 3: `alt-3`
  - Workspace 4: `alt-4`
  - Workspace 5: `alt-5`
  - Workspace 6: `alt-6`
  - Workspace 7: `alt-7`
  - Workspace 8: `alt-8`
  - Workspace 9: `alt-9`
- **Move Windows to Workspaces**:
  - Move to Workspace 1: `alt-shift-1`
  - Move to Workspace 2: `alt-shift-2`
  - Move to Workspace 3: `alt-shift-3`
  - Move to Workspace 4: `alt-shift-4`
  - Move to Workspace 5: `alt-shift-5`
  - Move to Workspace 6: `alt-shift-6`
  - Move to Workspace 7: `alt-shift-7`
  - Move to Workspace 8: `alt-shift-8`
  - Move to Workspace 9: `alt-shift-9`
- **Workspace Navigation**:
  - Workspace Back and Forth: `alt-tab`
  - Move Workspace to Monitor: `alt-shift-tab`
- **Enter Service Mode**: `alt-shift-;`

## Service Mode Bindings

- **Reload Config and Exit Service Mode**: `esc`
- **Reset Layout**: `r`
- **Toggle Floating/Tiling Layout**: `f`
- **Close All Windows But Current**: `backspace`
- **Join with Adjacent Windows**:
  - Join Left: `alt-shift-h`
  - Join Down: `alt-shift-j`
  - Join Up: `alt-shift-k`
  - Join Right: `alt-shift-l`

## Window Detection Rules

- **Brave Browser** (`com.brave.Browser`): Move to Workspace 1
- **Alacritty** (`org.alacritty`): Move to Workspace 2
- **VSCode** (`com.microsoft.VSCode`): Move to Workspace 3
- **Obsidian** (`md.obsidian`): Move to Workspace 4
