# home/common.nix
# Home Manager settings shared across all users/hosts where it's applied
{ config, pkgs, lib, inputs, ... }:

{
  # Home Manager Packages (available to the user)
  #home.packages = with pkgs; [
  #  htop
  #  neofetch
  #  ripgrep
  #  fd
  #];

  # Basic shell configuration (example using bash)
  #programs.bash = {
  #  enable = true;
  #  shellAliases = {
  #    ll = "ls -l";
  #    update = "sudo nixos-rebuild switch --flake '.#${config.networking.hostName}'"; # Requires correct hostname set
  #    update-flake = "nix flake update && sudo nixos-rebuild switch --flake '.#${config.networking.hostName}'";
  #  };
  #  historyControl = [ "ignoredups" "erasedups" ];
  #};

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
      # Add other git config here
    };
  };

  # Common dotfiles managed by Home Manager
  home.file.".config/common-config.txt".text = ''
    This is a common configuration file managed by Home Manager.
  '';

  # State version for Home Manager (align with NixOS or manage separately)
  home.stateVersion = "24.11";
}
