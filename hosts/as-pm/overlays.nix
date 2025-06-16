{
  pkgs,
  lib,
  customOpensshOverlayModule,
  opensshActualPatchFile,
  cursorOverlayModule,
  ...
}:
{
  nixpkgs.overlays = [
    # Apply the custom OpenSSH overlay
    ((import customOpensshOverlayModule) { patchFile = opensshActualPatchFile; })

    # Apply the Cursor overlay with host-specific parameters
    ((import cursorOverlayModule { inherit pkgs lib; }) {
      newCursorVersion = "1.0.0";
      newCursorUrl = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/linux/x64/Cursor-1.0.0-x86_64.AppImage";
      newCursorSha256 = "HJiT3aDB66K2slcGJDC21+WhK/kv4KCKVZgupbfmLG0=";
    })
  ];
}
