# modules/nixos/sunshine.nix
{ pkgs, ... }:

{
  # The sunshine package is needed
  environment.systemPackages = [ pkgs.sunshine ];

  # Wrapper for permissions, needed for virtual keyboard/mouse
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };

  # Enable and configure the sunshine service
  services.sunshine = {
    enable = true;
    settings = {
      key_rightalt_to_key_win = "enabled";
    };
    autoStart = false;
    openFirewall = true;
  };
}
