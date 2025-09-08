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
    sha256 = "1d0l1xikfp37zk9bzhjg73n78xvgwm5xm2k7q3hjkmab0lfx295m";
    message = ''
      This file needs to be manually downloaded from the Berkeley Graphics
      site (https://berkeleygraphics.com/accounts). An email will be sent to
      get a download link.

      Select the variant that matches “${variant}”
      & download the zip file.

      Then run:

      mv \$PWD/berkeley-mono-typeface.zip \$PWD/${name}
      nix-prefetch-url --type sha256 file://\$PWD/${name}
      If you want nerd fonts:
      nerd-font-patcher -c ${name}
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

    mkdir -p $out/share/fonts/truetype
    find . -name "*.ttf" -exec install -m444 -t $out/share/fonts/truetype {} +

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
