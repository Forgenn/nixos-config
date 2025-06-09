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
    ./hardware-configuration.nix # Node-specific hardware configuration
    ./master-k3s-config.nix # k3s config
  ];

  networking.hostName = "dubois";
}
