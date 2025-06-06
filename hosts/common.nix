# hosts/common.nix
# Settings applied to ALL hosts defined in flake.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./../modules/nixos/base.nix # Import base module for common packages/settings
  ];

  # Basic system setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.useDHCP = lib.mkDefault true;

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.root.initialHashedPassword = "*";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Nix settings
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
    gc = {
      # Automatic garbage collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim
  ];

  system.stateVersion = "24.11";
}
