# Module: Workstation Configuration
# Purpose: Terminal workstation tools plus a local GUI terminal
# Platform: All
{...}: {
  imports = [./terminal-workstation.nix ../modules/ghostty.nix];
}
