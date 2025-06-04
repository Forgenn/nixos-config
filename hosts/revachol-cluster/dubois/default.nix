{
<<<<<<< Updated upstream
  config,
  pkgs,
  lib,
  inputs,
  user,
=======
>>>>>>> Stashed changes
  ...
}:

{
  imports = [
    ../../common.nix # Global common configuration
    ../revachol-common.nix # Cluster-specific common configuration
    ./hardware-configuration.nix # Node-specific hardware configuration
<<<<<<< Updated upstream
    ./k3s-config.nix # k3s config
=======
    ./master-k3s-config.nix # k3s config
>>>>>>> Stashed changes
  ];

  networking.hostName = "dubois";
}
