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
  nixpkgs.overlays = [
    #  # Apply the custom OpenSSH overlay
    #  ((import customOpensshOverlayModule) { patchFile = opensshActualPatchFile; })
    #
    #  # Apply the Cursor overlay with host-specific parameters
    #  ((import cursorOverlayModule { inherit pkgs lib; }) {
    #    newCursorVersion = "1.1.3";
    #    newCursorUrl = "https://downloads.cursor.com/production/979ba33804ac150108481c14e0b5cb970bda3266/linux/x64/Cursor-1.1.3-x86_64.AppImage";
    #    newCursorSha256 = "sha256-mOwWNbKKykMaLFxfjaoGGrxfyhLX++fqJ0TXQtKVD8c=";
    #  })
    (self: super: {
      # Temporal 6.15.4 kernel fix for ghostty (kernel version makes it unusably slow due to io_uring)
      ghostty = super.ghostty.overrideAttrs (_: {
        preBuild = ''
          shopt -s globstar
          sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
          shopt -u globstar
        '';
      });
    })
  ];
}
