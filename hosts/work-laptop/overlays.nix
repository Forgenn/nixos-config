{
  pkgs,
  lib,
  cursorOverlayFile,
  customOpensshOverlayFile,
  opensshDontCheckPermPatch,
  ...
}:
{
  nixpkgs.overlays = [
    (
      (import customOpensshOverlayFile {
        inherit pkgs lib; # pkgs here is the set *before* this specific overlay is fully applied by Nix
        patchFile = opensshDontCheckPermPatch;
      })
    )
    # Your inline overlay for Cursor
    (
      # Call the outer function of the overlay, passing pkgs and lib
      (import cursorOverlayFile { inherit pkgs lib; }) # Adjust path if needed
        # Call the inner function with your specific Cursor details
        {
          newCursorVersion = "1.0.0";
          newCursorUrl = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/linux/x64/Cursor-1.0.0-x86_64.AppImage";
          # Replace with the actual SHA256 hash after the first failed build
          newCursorSha256 = "HJiT3aDB66K2slcGJDC21+WhK/kv4KCKVZgupbfmLG0=";
          # cursorPname = "code-cursor"; # Optional, defaults to "code-cursor" in the overlay file
        }
    )
  ];
}
