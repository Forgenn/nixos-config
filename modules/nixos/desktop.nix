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
    ];

    programs.fish = {
      enable = true;
      shellInit = "starship init fish | source";
    };

    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
        command_timeout = 1300;
        scan_timeout = 50;
        format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$golang$python$kubernetes[](fg:#212736 bg:#1d2230)$time[](fg:#1d2230)\n$character";
        directory = {
          style = "fg:#e3e5e5 bg:#769ff0";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };
        git_branch = {
          symbol = "";
          style = "bg:#394260";
          format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
        };

        git_status = {
          style = "bg:#394260";
          format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        golang = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        python = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        time = {
          disabled = false; # Nix boolean value
          time_format = "%R";
          style = "bg:#1d2230";
          format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
        };
        character = {
          success_symbol = "[](bold green) ";
          error_symbol = "[✗](bold red) ";
        };
      };
    };

    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        background-opacity = 0.95;
        background-blur = 40;
        shell-integration = "fish";
        command = "fish";
        keybind = [
          "ctrl+backspace=text:\\x15"
        ];
      };
    };

    programs.rofi.enable = true;
    programs.rofi.theme = "solarized_alternate.rasi";
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
