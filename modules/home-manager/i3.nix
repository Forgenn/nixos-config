{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.picom.enable = true;
  # Define i3 settings under the xsession path
  xsession.windowManager.i3 = {
    # Enable this module to generate the config and potentially set things up
    enable = true;
    # Specify the package (consistent with configuration.nix)
    package = pkgs.i3-gaps;

    # The entire i3 configuration now goes under 'config' here
    config =
      let
        mod = "Mod4";
        alt = "Mod1";
        refresh_i3status = "${pkgs.psmisc}/bin/killall -SIGUSR1 i3status";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        launcher = "${pkgs.rofi}/bin/rofi -show run";
        lockScreenCmd = "${pkgs.systemd}/bin/systemd-run --user --quiet ${pkgs.systemd}/bin/loginctl lock-session";
        wallpaper = pkgs.fetchurl {
          url = "https://nextcloud.monederobox.xyz/s/wRf36sseHsgSnfW";
          sha256 = "sha256-HC8Npib57scngiRBkorlUprhpZoymTF7lRopHjLpmco=";
          name = "i3-wallpaper.jpg";
        };
      in
      {
        # All your previous config settings go here:
        modifier = mod;
        terminal = terminal; # Define i3 variable (used internally by HM potentially)
        fonts = {
          names = [ "pango:monospace 8" ];
        };
        gaps = {
          inner = 10;
        };
        window.border = 0;
        #window.defaultFloatingBorder = "pixel 0";
        window.commands = [
          {
            criteria = {
              class = "^.*";
            };
            command = "border pixel 1";
          }
          # Plasma compatibility improvements
          {
            criteria = {
              window_role = "pop-up";
            };
            command = "floating enable";
          }
          {
            criteria = {
              window_role = "task_dialog";
            };
            command = "floating enable";
          }
          {
            criteria = {
              class = "yakuake";
            };
            command = "floating enable";
          }
          {
            criteria = {
              class = "systemsettings";
            };
            command = "floating enable";
          }
          {
            criteria = {
              class = "plasmashell";
            };
            command = "floating enable";
          }
          {
            criteria = {
              class = "Plasma";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              title = "plasma-desktop";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              title = "win7";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              class = "krunner";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              class = "Kmix";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              class = "Klipper";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              class = "Plasmoidviewer";
            };
            command = "floating enable, border none";
          }
          {
            criteria = {
              class = "(?i)*nextcloud*";
            };
            command = "floating disable";
          }
          {
            criteria = {
              class = "plasmashell";
              window_type = "notification";
            };
            command = "border none, move position 70 ppt 81 ppt";
          }
          {
            criteria = {
              title = "Desktop @ QRect.*";
            };
            command = "kill, floating enable, border none";
          }

          {
            criteria = {
              class = "(?i)task";
            };
            command = "floating disable";
          }
        ];
        #noFocus = [
        #    { criteria = { class = "plasmashell"; window_type = "notification"; }; }
        #  ];
        floating.modifier = mod;
        #tiling.drag = "modifier titlebar";
        workspaceOutputAssign = [
          {
            output = "eDP-1";
            workspace = "1";
          }
          {
            output = "eDP-1";
            workspace = "2";
          }
          {
            output = "eDP-1";
            workspace = "3";
          }
          {
            output = "HDMI-1";
            workspace = "4";
          }
          {
            output = "HDMI-1";
            workspace = "5";
          }
          {
            output = "HDMI-1";
            workspace = "6";
          }
          {
            output = "HDMI-1";
            workspace = "7";
          }
        ];
        keybindings = pkgs.lib.mkOptionDefault ({
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+Shift+q" = "kill";
          "${mod}+d" = "exec ${launcher}";
          "${mod}+p" = "exec ${lockScreenCmd}";

          # --- Focus ---
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus down";
          "${mod}+l" = "focus up";
          "${mod}+semicolon" = "focus right";
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          # --- Moving windows ---
          "${mod}+Shift+j" = "move left";
          "${mod}+Shift+k" = "move down";
          "${mod}+Shift+l" = "move up";
          "${mod}+Shift+semicolon" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          # --- Layout ---
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";

          # --- Tiling/Floating ---
          "${mod}+Shift+t" = "floating toggle"; # Your config used Shift+t, not Shift+space
          "${mod}+space" = "focus mode_toggle";

          # --- Focus Parent/Child ---
          "${mod}+a" = "focus parent";
          # "${mod}+d" = "focus child"; # Your config had this commented out

          # --- Workspace switching ---
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+0" = "workspace number 10";

          # --- Moving windows to workspaces ---
          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
          "${mod}+Shift+0" = "move container to workspace number 10";

          # --- Reload/Restart/Exit ---
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+e" =
            "exec \"${pkgs.i3-gaps}/bin/i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'\"";

          # --- Resize Mode ---
          "${mod}+r" = "mode \"resize\"";

          "XF86AudioRaiseVolume" =
            "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10% && ${refresh_i3status}";
          "XF86AudioLowerVolume" =
            "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10% && ${refresh_i3status}";
          "XF86AudioMute" =
            "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle && ${refresh_i3status}";
          "XF86AudioMicMute" =
            "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle && ${refresh_i3status}";
        });
        modes = {
          resize = {
            "j" = "resize shrink width 10 px or 10 ppt";
            "k" = "resize grow height 10 px or 10 ppt";
            "l" = "resize shrink height 10 px or 10 ppt";
            "semicolon" = "resize grow width 10 px or 10 ppt";
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            # Exit resize mode
            "Return" = "mode \"default\"";
            "Escape" = "mode \"default\"";
            "${mod}+r" = "mode \"default\"";
          };
        };
        startup = [
          #{ command = "${pkgs.dex}/bin/dex --autostart --environment i3"; notification = false; always = true; }
          {
            command = "${pkgs.feh}/bin/feh --bg-fill --no-xinerama ${wallpaper}";
            notification = false;
            always = true;
          }
          #{ command = "${pkgs.dunst}/bin/dunst"; notification = false; always = true; }
          {
            command = "${pkgs.picom}/bin/picom";
            notification = false;
            always = true;
          }
        ];
        bars = [ { command = ":"; } ]; # Optional bar config
      }; # End config block
  }; # End xsession.windowManager.i3 block
}
