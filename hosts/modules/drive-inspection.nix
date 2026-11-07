# Module: Drive inspection (SMART)
# Purpose: GSmartControl GUI and smartmontools for checking disk health
# Platform: macOS only
#
# nixpkgs does not build gsmartcontrol for Darwin, so both tools come from
# Homebrew (the formula pulls in its GTK3 stack). smartctl reads the internal
# NVMe drive without root.
#
# USB limitation: macOS has no userspace SCSI/ATA pass-through, so smartctl
# fails with "Operation not supported by device" on USB-attached drives. Reading
# them needs the third-party SAT SMART kernel extension, which requires Reduced
# Security, Recovery Mode approval and a reboot. That cannot be declared here
# and is intentionally not enabled.
_: {
  homebrew.brews = [
    "gsmartcontrol" # GUI for smartctl — https://gsmartcontrol.shaduri.dev/
    "smartmontools" # smartctl/smartd; also a gsmartcontrol dependency — https://www.smartmontools.org/
  ];
}
