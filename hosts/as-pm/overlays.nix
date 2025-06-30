{
  pkgs,
  lib,
  customOpensshOverlayModule,
  opensshActualPatchFile,
  cursorOverlayModule,
  ...
}:
{
  # Not using overlays currently
  #nixpkgs.overlays = [
  #  # Apply the custom OpenSSH overlay
  #  ((import customOpensshOverlayModule) { patchFile = opensshActualPatchFile; })
  #
  #  # Apply the Cursor overlay with host-specific parameters
  #  ((import cursorOverlayModule { inherit pkgs lib; }) {
  #    newCursorVersion = "1.1.3";
  #    newCursorUrl = "https://downloads.cursor.com/production/979ba33804ac150108481c14e0b5cb970bda3266/linux/x64/Cursor-1.1.3-x86_64.AppImage";
  #    newCursorSha256 = "sha256-mOwWNbKKykMaLFxfjaoGGrxfyhLX++fqJ0TXQtKVD8c=";
  #  })
  #];
}
