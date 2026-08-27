# NFS server + the CSI service account.
#
# Ownership split (see migration report Q4 for the full reasoning):
#   revachol-pool/k8s-data/**  -> democratic-csi owns it exclusively, via the ZFS `sharenfs`
#                                  property (writes /etc/exports.d/zfs.exports). Nothing here
#                                  ever touches that subtree.
#   revachol-pool/media/**     -> NixOS owns it exclusively, via services.nfs.server.exports
#                                  (writes /etc/exports). `sharenfs` must be explicitly OFF on
#                                  these datasets so the two mechanisms can never fight over
#                                  the same property — currently it is NOT off (both
#                                  media/books and media/downloads are live via `sharenfs`
#                                  today), so this needs a one-time
#                                  `zfs set sharenfs=off revachol-pool/media/books
#                                   revachol-pool/media/downloads`
#                                  during migration validation (Phase 4), after which this
#                                  file's exports take over cleanly.
{ config, lib, pkgs, ... }:

let
  clusterNodes = [ "dubois.home" "cuno.home" "katsuragi.home" ];
  nodeExport = "rw,sec=sys,no_subtree_check,insecure,no_root_squash";
in
{
  boot.supportedFilesystems = [ "nfs" ];
  boot.blacklistedKernelModules = [ "nfsv3" ];
  services.rpcbind.enable = true;

  services.nfs.settings.nfsd = {
    rdma = false;
    vers3 = false;
    vers4 = false;
    "vers4.0" = false;
    "vers4.1" = false;
    "vers4.2" = true;
  };

  services.nfs.server = {
    enable = true;
    exports = lib.concatStringsSep "\n" (
      map (
        ds:
        "/revachol-pool/media/${ds} "
        + lib.concatMapStringsSep " " (h: "${h}(${nodeExport})") clusterNodes
      ) [ "books" "downloads" ]
      # "music" intentionally omitted for now — navidrome/lidarr's music library currently
      # lives inside opencloud's PVC (pvc-a2248f1d-...), not a dedicated dataset. Add a line
      # here once that tech debt (gitops-cluster README) is actually resolved — do NOT
      # pre-create an empty music export, it'll just be one more unexplained thing.
    );
  };

  # Service account democratic-csi SSHes in as. Only needs a public key here — the private
  # half is the agenix secret `nas_node_key` decrypted on the k3s nodes, and dolores never
  # needs to be able to decrypt it (see migration report Q5: dolores stays out of
  # secrets.nix's `systems` list entirely).
  users.users.revachol-csi-user = {
    isSystemUser = true;
    group = "revachol-csi-user";
    uid = 1003; # pinned to match the live Ubuntu/Debian box — do not let this float
    home = "/home/revachol-csi-user";
    createHome = true;
    shell = pkgs.bashInteractive; # democratic-csi execs `sudo zfs ...` over this session
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAhvkwC0aIg5CoS5SirfgJRiak7rW4QUawX9QoJlVS4t"
    ];
  };
  users.groups.revachol-csi-user.gid = 1003;

  # democratic-csi's driver config has sudoEnabled=true and expects passwordless zfs/zpool
  # access for this user. The `zfs allow` delegation half of narrowing this is DONE --
  # revachol-csi-user now holds create,destroy,mount,snapshot,clone,promote,rollback,
  # userprop,quota,reservation,refquota,refreservation,receive,send on revachol-pool/k8s-data
  # (local+descendent, so it covers .../main and .../snapshots too). Deliberately NOT
  # switching the driver config off sudoEnabled or narrowing this rule yet: Linux OpenZFS
  # restricts mount/share to root regardless of delegation (kernel constraint, not a
  # democratic-csi limitation), so this still needs `sudoEnabledCommands` scoped to just
  # zfs mount/unmount/share/unshare -- untested against this deployment's actual
  # democratic-csi version, and getting it wrong breaks cluster-wide PVC provisioning.
  # Verify a real provision+delete cycle works under the narrowed config before touching
  # this rule.
  security.sudo.extraRules = [
    {
      users = [ "revachol-csi-user" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
