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
    ./../common.nix
    ../modules/cursor.nix
  ];
  home.homeDirectory = "/home/${user}";
  # User-specific packages
  home.packages = with pkgs; [
    fish
  ];

  # Override or extend common settings
  programs.bash.enable = false;
  programs.fish = {
    enable = true;
  };

  home.stateVersion = "24.11";
}
