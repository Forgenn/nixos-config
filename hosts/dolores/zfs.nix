# ZFS import + housekeeping for revachol-pool.
#
# Deliberately does NOT declare fileSystems entries for anything under
# /revachol-pool — ZFS mounts its own datasets via zfs-mount.service, and adding
# a second declarative mounter creates boot-time ordering fights. extraPools is
# the only hook needed to get the pool imported at boot.
{ config, lib, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "revachol-pool" ];

  # Captured live from the Ubuntu/Debian box's /etc/hostid before migration — MUST match,
  # or import mismatches show up as -f-required errors on every boot instead of the pool
  # just coming up. Do not regenerate this.
  networking.hostId = "181dbb03";

  # NEVER run `zpool upgrade` on this pool. NixOS 25.05/26.05's OpenZFS (2.3.5 / 2.4.3)
  # reads the pool's current feature set (2.3.4-era: raidz_expansion, fast_dedup, longname,
  # block_cloning all already active) forward-compatibly. Upgrading trades that headroom for
  # nothing — there's no feature this pool actually needs — and burns any rollback path
  # through an older ZFS if one is ever needed again.

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
    pools = [ "revachol-pool" ];
  };

  services.zfs.trim.enable = false; # pool is spinning disks, not SSD — trim is a no-op/harmful here

  # TODO: wire zed to ntfy once a notification token exists. Nobody currently gets paged on
  # DEGRADED, checksum errors, or scrub failures — that gap is how the mirror sat DEGRADED
  # unnoticed for ~5 months before this migration. Minimum viable version:
  #
  # services.zfs.zed.settings = {
  #   ZED_EMAIL_ADDR = [ ];
  #   ZED_NOTIFY_VERBOSE = true;
  # };
  # (or a custom zedlet posting to ntfy — see infra/ntfy in gitops-cluster for the existing
  # topic/URL pattern used elsewhere in the cluster)

  # No swap on this box lives on a zvol — known deadlock source under memory pressure.
  # Swap, if any, should be a plain partition on the OS disk in hardware-configuration.nix.
}
