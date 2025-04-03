# hosts/common.nix
# Settings applied to ALL hosts defined in flake.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./../modules/base.nix # Import base module for common packages/settings
  ];

  # Basic system setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.useDHCP = lib.mkDefault true; # Can be overridden by host-specific config
  time.timeZone = "Europe/Madrid"; # Set your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Basic user setup (system-level)
  users.users.root.initialHashedPassword = "*"; # Lock root account by default

  # SSH daemon settings (common for most systems)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no"; # Good practice: disable root login
      PasswordAuthentication = false; # Good practice: use SSH keys only
    };
  };

  # Nix settings
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
    gc = { # Automatic garbage collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # System packages available globally (consider carefully, user packages are often better via HM)
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim # Or your preferred basic editor
  ];

  # Allow unfree packages if needed (e.g., for drivers, certain apps)
  nixpkgs.config.allowUnfree = true;

  # System settings
  system.stateVersion = "24.11"; # Set to the NixOS version you're basing on
}
