# File: custom-openssh-overlay.nix
# This overlay provides a differently named, patched version of openssh.
# It expects 'pkgs', 'lib', and 'patchFile' (absolute path to the patch) to be passed.

{ patchFile }:
{ pkgs, lib }:
final: prev: {
  # self is the final pkgs, super is the previous pkgs

  # This will be our new package name, e.g., pkgs.openssh-no-checkperm
  openssh-no-checkperm = prev.openssh.overrideAttrs (oldAttrs: {
    # Create a distinct package name by appending a suffix
    pname = "${oldAttrs.pname or "openssh"}-no-checkperm";
    # Version remains the same as the base openssh package
    #version = oldAttrs.version;

    patches = (oldAttrs.patches or [ ]) ++ [
      patchFile # Apply the provided patch
    ];

  });
}
