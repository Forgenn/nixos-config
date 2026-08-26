{
  config,
  pkgs,
  lib,
  inputs,
  user,
  ...
}:

{
  imports = [
    ../../common.nix # Global common configuration
    ../revachol-common.nix # Cluster-specific common configuration
    ../node-config.nix # k3s server-role config (HA control-plane member, see node-config.nix)
    ./hardware-configuration.nix # Node-specific hardware configuration
  ];

  networking.hostName = "katsuragi";
}
