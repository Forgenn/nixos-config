# hosts/laptop/default.nix
{ config, pkgs, lib, inputs, user, ... }: # Note the 'user' arg passed from flake.nix

{
  imports = [
    # Include the hardware configuration specific to this laptop
    ./hardware-configuration.nix
    # You could import other laptop-specific modules here
  ];

  

  # Hostname
  networking.hostName = "nixos";
  
  # Laptop specific settings

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Install Bolt Daemon
  services.hardware.bolt.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;
  
  # Define the primary user account on this system
  users.users.${user} = {
    isNormalUser = true;
    description = "ntb";
    extraGroups = [ "docker" "networkmanager" "wheel" "video" "audio" ]; # 'wheel' for sudo access
    initialHashedPassword = "*"; # Set a password manually or use home-manager/impermanence
    openssh.authorizedKeys.keys = [
      # Add your SSH public key(s) here
    ];
  };

  security.sudo.wheelNeedsPassword = true; # Or true if you prefer

  # Firewall settings (example)
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Laptop specific packages (less common, prefer home-manager)
  environment.systemPackages = with pkgs; [ 
        pkgs.chromium
        vscode
        ghostty
        slack
        kdePackages.plasma-browser-integration
        kdePackages.plasma-thunderbolt
   ];
  ##########################
  #  Program configuration
  ##########################
  home-manager.users.${user} = {pkgs, ...}: {
  programs.ssh.enable = true;
  
  programs.git = {
      # Use lib.mkOverride to ensure these values take precedence over
      # any potential definitions in home.nix or common.nix.
      # Priority 10 is a common choice for overrides.
      userName = lib.mkOverride 10 "ntb";
      userEmail = lib.mkOverride 10 "pol.monedero@aistechspace.com";
    };
  
  #home.homeDirectory = /home/${user};

 };
}
