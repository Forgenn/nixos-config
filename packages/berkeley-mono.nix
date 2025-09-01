{
  lib,
  requireFile,
  stdenvNoCC,
  unzip,
  variant ? "",
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "berkeley-mono";
  version = "v1.1.3";

  src = requireFile rec {
    name = "${finalAttrs.pname}-${variant}-${finalAttrs.version}.zip";
    sha256 = "113d1lrrrdmaygfsnb9pi1i00vjrs3mb22gsj9lj8i4zkw6m18s2";
    message = ''
      This file needs to be manually downloaded from the Berkeley Graphics
      site (https://berkeleygraphics.com/accounts). An email will be sent to
      get a download link.

      Select the variant that matches “${variant}”
      & download the zip file.

      Then run:

      mv \$PWD/berkeley-mono-typeface.zip \$PWD/${name}
      nix-prefetch-url --type sha256 file://\$PWD/${name}
    '';
  };

  nativeBuildInputs = [
    unzip
  ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall

    fontDir=$(find . -type d -name 'TX-02-L0183W0Z' -print -quit)
    if [ -z "$fontDir" ]; then
      echo "Could not find font directory TX-02-L0183W0Z"
      exit 1
    fi
    install -D -m444 -t $out/share/fonts/truetype "$fontDir"/*.ttf

    runHook postInstall
  '';

  meta = {
    description = "Berkeley Mono Typeface";
    longDescription = "";
    homepage = "https://berkeleygraphics.com/typefaces/berkeley-mono";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
})
