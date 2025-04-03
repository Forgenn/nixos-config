# hosts/server/default.nix
{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [
    # Include the hardware configuration specific to this server
    ./hardware-configuration.nix
  ];

  # Hostname
  networking.hostName = "server";

  # Server specific settings
  # Example: Disable power management features typically needed on laptops
  services.powerManagement.enable = false;

  # Example: Ensure network is configured statically if needed
  # networking.useDHCP = false;
  # networking.interfaces.eth0.ipv4.addresses = [ { address = "192.168.1.10"; prefixLength = 24; } ];
  # networking.defaultGateway = "192.168.1.1";
  # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Define the primary user account on this system
   users.users.${user} = {
    isNormalUser = true;
    description = "Primary Server User";
    extraGroups = [ "wheel" ]; # 'wheel' for sudo access
    initialHashedPassword = "*";
    openssh.authorizedKeys.keys = [
      # Add your SSH public key(s) here (can be the same or different)
    ];
  };
   # Allow user 'user1' to use sudo
  security.sudo.wheelNeedsPassword = true; # Usually requires password on servers

  # Firewall settings (more restrictive usually)
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ]; # Allow SSH
  # Add other ports needed for server applications (e.g., 80, 443 for web server)

  # Server specific packages/services
  # environment.systemPackages = with pkgs; [ htop ];
  # services.nginx.enable = true;
}
