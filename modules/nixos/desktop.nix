# modules/desktop.nix
# Example module for desktop-specific settings, imported by laptop config
{
  self,
  config,
  pkgs,
  lib,
  user,
  ...
}:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      feh
      rofi
      rofi-power-menu
      picom
    ];
  };

  services.picom = {
    enable = true;
    settings = {
      blur = {
        method = "gaussian";
        size = 10;
        deviation = 5.0;
      };
      blur-background = true;
    };
  };

  #######################
  # SDDM Custom config
  #######################
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage (self + /packages/sddm-astronaut-theme.nix) {
      #theme = "black_hole"; # default is astronaut
      theme = "astronaut";
      themeConfig = {
        General = {
          HeaderText = "Hi";
          #Background = "/home/user/Desktop/wp.png";
          FontSize = "10.0";
        };
      };
    })
  ];

  services.displayManager.sddm = {
    enable = true;
    enableHidpi = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };

  # hm configuration
  home-manager.users.${user} = {

    imports = [
      ../home-manager/i3.nix
      ../home-manager/ghostty.nix
      ../home-manager/fish+starship.nix
    ];

  };

  services.displayManager.defaultSession = "plasma6-i3wm+i3";
  # Setup desktop services
  services.xserver.displayManager = {
    session = [
      {
        manage = "desktop";
        name = "plasma6-i3wm";
        start = ''exec env KDEWM=${pkgs.i3-gaps}/bin/i3 ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11'';
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

  services.desktopManager.plasma6.enable = true;

  # Configure sound server
  services.pulseaudio.enable = false; # Use pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true; # If needed
  };
}
