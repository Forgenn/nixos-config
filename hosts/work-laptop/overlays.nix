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
          newCursorVersion = "0.50.7";
          newCursorUrl = "https://downloads.cursor.com/production/02270c8441bdc4b2fdbc30e6f470a589ec78d60d/linux/x64/Cursor-0.50.7-x86_64.AppImage";
          # Replace with the actual SHA256 hash after the first failed build
          newCursorSha256 = "ukYsLtwnM+yjeDX24Bls7c0MhxeMGOemdQFF6t8Mqvg=";
          # cursorPname = "code-cursor"; # Optional, defaults to "code-cursor" in the overlay file
        }
    )
  ];
}
