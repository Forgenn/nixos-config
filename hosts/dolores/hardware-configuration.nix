# PLACEHOLDER — do not use as-is.
#
# Every other host's hardware-configuration.nix in this repo is raw
# `nixos-generate-config` output (UUIDs, initrd modules, bootloader hints specific
# to that exact install). This one can't be pre-written the same way because the
# real file only exists after the NixOS installer has partitioned dolores's OS
# disk (the Kingston SA400M8120G / sdc — NOT the two 8TB pool drives, which must
# be physically disconnected before the installer ever runs).
#
# During the install:
#   1. Confirm you're partitioning /dev/disk/by-id/<the Kingston SSD>, not sda/sdb.
#   2. Run `nixos-generate-config --root /mnt` from the installer.
#   3. Replace this entire file with its output verbatim.
#   4. Do not add fileSystems entries for anything under /revachol-pool here —
#      that's zfs.nix's job via boot.zfs.extraPools, not this file's.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Known from the live box, likely but not guaranteed to match the fresh install
  # (SATA AHCI, not NVMe — dolores's OS disk is a SATA SSD, unlike the other 3 nodes):
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # fileSystems."/" and "/boot" — fill in from nixos-generate-config's actual output.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
