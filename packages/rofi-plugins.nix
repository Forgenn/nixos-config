{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  rofi,
}:

stdenvNoCC.mkDerivation {
  name = "rofi-launchers";

  src = fetchFromGitHub {
    owner = "adi1090x";
    repo = "rofi";
    rev = "fb7011e";
    hash = "sha256-wwLcb7z5jCKgKPY5mNhYIoPvKbVO3PwULrJ+Lm3Ra7g=";
  };

  buildInputs = [ rofi ];

  # After installation, replace static references to references from the nix store
  postPatch = ''
    files=$(find files/scripts -type l)
    for file in $files; do
      substituteInPlace $file \
        --replace-fail '$HOME/.config/rofi' "$out/share" \
        --replace-fail "rofi " "${lib.getExe rofi} "
    done

    files=$(find files/launchers -type f -name "*.rasi")
    for file in $files; do
      substituteInPlace $file \
        --replace-quiet '~/.config/rofi' "$out/share" 
    done
  '';

  installPhase = ''
    runHook preInstall

    # Install all scripts as binaries
    mkdir -p $out/bin
    for script in files/scripts/*; do
      install -Dm755 $script $out/bin/$(basename $script)
    done

    # Install Fonts
    mkdir -p "$out/share/fonts"
    cp -r fonts/* "$out/share/fonts"

    # Install other necessary files
    mkdir -p "$out/share"
    cp -r files/* "$out/share"

    runHook postInstall
  '';

  meta = {
    description = "A collection of rofi launchers";
    homepage = "https://github.com/adi1090x/rofi";
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
  };
}
