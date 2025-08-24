# /path/to/your/imports/hyprland-user-config.nix

{
  config,
  pkgs,
  lib,
  user,
  ...
}:

let
  mainMod = "SUPER"; # The "Windows" key
  terminal = "${pkgs.ghostty}/bin/ghostty";
  fileManager = "${pkgs.nautilus}/bin/nautilus"; # The file manager to launch
  launcher = "${pkgs.rofi-wayland}/bin/rofi -show drun"; # The app launcher
  # Define the derivation once. It will be converted to a path string where needed.
  wallpaperDerivation = pkgs.fetchurl {
    url = "https://nextcloud.monederobox.xyz/s/wRf36sseHsgSnfW/download/disco_elysium_wallpaper.jpg";
    sha256 = "sha256-jyAh9KcIFQULwp+wja08xxm4yC7KuDvnx2Tczkd18fk=";
    name = "wallpaper.jpg";
  };

in
{
  # This file should be imported into your main NixOS configuration.
  # It defines the Hyprland desktop environment for a single user via Home Manager.

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
    config.hyprland = {
      "org.freedesktop.impl.portal.desktop.hyprland" = "default";
      "org.freedesktop.impl.portal.ScreenCast" = "default";
    };
  };

  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.${user} =
    { pkgs, ... }:
    {

      home.packages = with pkgs; [
        wlogout
        ghostty
        nautilus
        kdePackages.polkit-kde-agent-1
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        systemd.enable = false;
        systemd.variables = [ "--all" ];
        settings = {
          monitor = "eDP-1,preferred,auto,1";
          env = "XCURSOR_SIZE,24";
          exec-once = [ "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1" ];
          input = {
            kb_layout = "us";
            follow_mouse = 1;
            touchpad.natural_scroll = false;
          };
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(89b4faee) rgba(b4befeec) 45deg";
            "col.inactive_border" = "rgba(494d64aa)";
            layout = "dwindle";
          };
          decoration = {
            rounding = 8;
          };
          animations.enabled = true;
          dwindle.pseudotile = true;
          bind = [
            # --- Applications & System ---
            "${mainMod}, RETURN, exec, ${terminal}"
            "${mainMod}, D, exec, ${launcher}"
            "${mainMod}, E, exec, ${fileManager}"
            "${mainMod} SHIFT, Q, killactive,"
            "${mainMod} SHIFT, M, exit,"
            "${mainMod}, L, exec, hyprlock"
            "${mainMod} SHIFT, L, exec, wlogout"
            "${mainMod}, F, fullscreen, 0"
            "${mainMod}, V, togglefloating,"
            "${mainMod}, P, pseudo,"
            "${mainMod}, J, togglesplit,"

            # --- Hyprland Reload ---
            "${mainMod} SHIFT, R, exec, ${pkgs.hyprland}/bin/hyprctl reload"

            # --- Change Focus (Vim-style) ---
            "${mainMod}, h, movefocus, l"
            "${mainMod}, j, movefocus, d"
            "${mainMod}, k, movefocus, u"
            "${mainMod}, l, movefocus, r"

            # --- Move Windows (Vim-style) ---
            "${mainMod} SHIFT, h, movewindow, l"
            "${mainMod} SHIFT, j, movewindow, d"
            "${mainMod} SHIFT, k, movewindow, u"
            "${mainMod} SHIFT, l, movewindow, r"

            # --- Switch Workspaces ---
            "${mainMod}, 1, workspace, 1"
            "${mainMod}, 2, workspace, 2"
            "${mainMod}, 3, workspace, 3"
            "${mainMod}, 4, workspace, 4"
            "${mainMod}, 5, workspace, 5"
            "${mainMod}, 6, workspace, 6"
            "${mainMod}, 7, workspace, 7"
            "${mainMod}, 8, workspace, 8"
            "${mainMod}, 9, workspace, 9"
            "${mainMod}, 0, workspace, 10"

            # --- Move Window to a Workspace ---
            "${mainMod} SHIFT, 1, movetoworkspace, 1"
            "${mainMod} SHIFT, 2, movetoworkspace, 2"
            "${mainMod} SHIFT, 3, movetoworkspace, 3"
            "${mainMod} SHIFT, 4, movetoworkspace, 4"
            "${mainMod} SHIFT, 5, movetoworkspace, 5"
            "${mainMod} SHIFT, 6, movetoworkspace, 6"
            "${mainMod} SHIFT, 7, movetoworkspace, 7"
            "${mainMod} SHIFT, 8, movetoworkspace, 8"
            "${mainMod} SHIFT, 9, movetoworkspace, 9"
            "${mainMod} SHIFT, 0, movetoworkspace, 10"

            # --- Scroll through existing workspaces ---
            "${mainMod}, mouse_down, workspace, e-1"
            "${mainMod}, mouse_up, workspace, e+1"

            # --- Resize Mode ---
            "${mainMod}, R, submap, resize"
          ];

          bindm = [
            # Move/resize windows with mainMod + LMB/RMB and dragging
            "${mainMod}, mouse:272, movewindow"
            "${mainMod}, mouse:273, resizewindow"
          ];

          windowrulev2 = [
            "float, class:^(pavucontrol)$"
            "float, class:^(blueman-manager)$"
            "float, class:^(nm-connection-editor)$"
            "float, title:^(Open File)$"
          ];
        };
      };

      # Configure Hyprland ecosystem components using their dedicated modules.

      services.hyprpaper = {
        enable = true;
        settings = {
          # The `${...}` interpolation correctly turns the derivation into a path string.
          wallpaper = ",${wallpaperDerivation}";
          ipc = "off";
        };
      };

      programs.hyprlock = {
        enable = true;
        settings = {
          background = {
            path = "${wallpaperDerivation}";
            blur_passes = 3;
          };
          label = [
            {
              text = "cmd[update:1000] echo \"$(date +'%H:%M')\"";
              color = "rgba(200, 200, 200, 0.8)";
              font_size = 80;
              font_family = "JetBrainsMono Nerd Font";
              position = "0, 80";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 600;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
