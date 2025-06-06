# overlays/default.nix
{ self, ... }:

{
  # A custom overlay for the Cursor editor
  cursor = import ./cursor-overlay.nix;

  # A custom overlay for OpenSSH to bypass permission checks
  openssh = import ./ssh-no-perm-overlay.nix {
    patchFile = self + "/patches/openssh-nix-dont-checkperm.patch";
  };
}
