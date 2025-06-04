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
    ../revachol-common.nix # Cluster-specific common configuration\
    ../node-config.nix # k3s default worker node config
    ./hardware-configuration.nix # Node-specific hardware configuration
  ];

  networking.hostName = "cuno";
}
