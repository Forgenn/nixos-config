# File: cursor-overlay.nix
{ pkgs, lib }:

{ newCursorVersion, newCursorUrl, newCursorSha256, cursorPname ? "code-cursor" }:

self: super:
let
  stdenvNoCC = pkgs.stdenvNoCC;
  fetchurl = pkgs.fetchurl;
  appimageTools = pkgs.appimageTools;
in
{
  ${cursorPname} = super.${cursorPname}.overrideAttrs (oldAttrs: rec {
    version = newCursorVersion;
    pname = oldAttrs.pname;

    # Ensure rsync is available during the installPhase (and other original nativeBuildInputs)
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ (
      lib.optionals stdenvNoCC.hostPlatform.isLinux [ pkgs.rsync ]
    );

    cursorRawAppImageSource = fetchurl {
      url = newCursorUrl;
      sha256 = newCursorSha256;
    };

    customWrappedAppimage = appimageTools.wrapType2 {
      inherit pname version;
      src = cursorRawAppImageSource;
      extraPkgs = pkgsFHS: (with pkgsFHS; [
        git
        openssh-no-checkperm
        # rsync is not needed here for the FHS env if only installPhase uses it.
        # However, having it here doesn't hurt if Cursor itself might ever call rsync.
        # For this specific error, nativeBuildInputs is the fix.
      ]);
      # If you want to re-add SSH_AUTH_SOCK forwarding for the FHS env (runtime):
      # extraMakeWrapperArgs = [ "--inherit-env" "SSH_AUTH_SOCK" ];
    };

    customAppimageContents = appimageTools.extractType2 {
      inherit pname version;
      src = cursorRawAppImageSource;
    };

    src = if stdenvNoCC.hostPlatform.isLinux then customWrappedAppimage else cursorRawAppImageSource;

    installPhase =
      (lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
        runHook preInstall
        mkdir -p $out/
        cp -r bin $out/bin
        rsync -a -q ${customAppimageContents}/usr/share $out/ --exclude "*.so" # rsync is used here
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace-fail "/usr/share/${pname}/${pname}" "$out/bin/${pname}"
        
        # If you want to re-add SSH_AUTH_SOCK for the outer wrapper (runtime):
        # wrapProgram $out/bin/${pname} \
        #   --inherit-env SSH_AUTH_SOCK \ 
        #   --add-flags "--update=false" \
        #   --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} --no-update" \
        #   --add-flags ""
        #
        # Original simpler wrapProgram if not handling SSH_AUTH_SOCK here:
         wrapProgram $out/bin/${pname} \
           --add-flags "--update=false" \
           --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} --no-update" \
           --add-flags "" # Assuming default commandLineArgs

      runHook postInstall
      '') +
      (lib.optionalString stdenvNoCC.hostPlatform.isDarwin oldAttrs.installPhase);

    passthru = oldAttrs.passthru // {
      sources = (oldAttrs.passthru.sources or {}) // {
        ${stdenvNoCC.hostPlatform.system} = cursorRawAppImageSource;
      };
    };
  });
}
