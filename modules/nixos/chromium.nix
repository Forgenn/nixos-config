{ pkgs, lib, ... }:
{
  ########################################################################
  # --- Chromium config ---
  ########################################################################
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = lib.mkDefault pkgs.kdePackages.plasma-browser-integration;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "haipckejfdppjfblgondaakgckohcihp" # milk cookie manager
      "eifflpmocdbdmepbjaopkkhbfmdgijcc" # json pro viewer
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # ublock origin lite
    ];
  };
}
