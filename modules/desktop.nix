# modules/desktop.nix
# Example module for desktop-specific settings, imported by laptop config
{ config, pkgs, lib, user, ... }:

{ 
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      feh
      rofi
      picom
    ];
  };
  
  # Import i3 hm configuration
  home-manager.users.${user}.imports = [
    ../home-manager/modules/i3.nix
  ];

  # Setup desktop services
  services.xserver.displayManager = {
     defaultSession = "plasma6-i3wm+i3";
     session = [
         {
             manage = "desktop";
             name = "plasma6-i3wm";
             start = ''exec env KDEWM=${pkgs.i3-gaps}/bin/i3 ${pkgs.plasma-workspace}/bin/startplasma-x11'';
         }
         #{
         #    manage = "desktop";
         #    name = "i3";
         #    start = ''exec ${pkgs.i3-gaps}/bin/i3'';
         #}
         #{
         #    manage = "desktop";
         #    name = "plasma6";
         #    start = ''exec ${pkgs.plasma-workspace}/bin/startplasma-x11'';
         #}
     ];
 };
  # Disable plasma kwin window manager
  systemd.user.services.plasma-kwin_x11.enable = false;

  # Enable the Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure sound server
  hardware.pulseaudio.enable = false; # Use pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true; # If needed
  };

  # Add some common desktop packages
  environment.systemPackages = with pkgs; [
    kdePackages.knewstuff
    kdePackages.kscreen 
  ];
}
