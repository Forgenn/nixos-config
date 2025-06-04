{
  pkgs,
  lib,
  user,
  ...
}:
{
  ##########################
  #  Program configuration
  ##########################
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };

  services.sunshine = {
    enable = true;
    settings = {
      key_rightalt_to_key_win = "enabled";
    };
    autoStart = false;
    openFirewall = true;
  };

  programs.kdeconnect.enable = true;

  ## CHROMIUM
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = lib.mkDefault pkgs.kdePackages.plasma-browser-integration;
  };

  services.openssh.settings.X11Forwarding = true;

  home-manager.users.${user} = {
    programs.ssh = {
      enable = true;
      # Impure Identity file config? Throws purity error if not a literal
      extraConfig = ''
        Host github.com
           AddKeysToAgent yes
           Hostname github.com
           IdentitiesOnly yes
           IdentityFile  ~/.ssh/id_ed25519_ais

        Host p.github.com
           AddKeysToAgent no
           Hostname github.com
           IdentitiesOnly yes
           IdentityFile  ~/.ssh/id_ed25519

        Host gitlab.com
                AddKeysToAgent yes
                Hostname gitlab.com
                IdentitiesOnly yes
                IdentityFile  ~/.ssh/id_ed25519
          
        Host bitbucket.org
                AddKeysToAgent yes
                Hostname bitbucket.org
                IdentitiesOnly yes
                IdentityFile  ~/.ssh/id_ed25519

      '';
    };
    programs.git = {
      # Use lib.mkOverride to ensure these values take precedence over
      # any potential definitions in home.nix or common.nix.
      # Priority 10 is a common choice for overrides.
      userName = lib.mkOverride 10 "ntb";
      userEmail = lib.mkOverride 10 "pol.monedero@aistechspace.com";
    };

    # --- Configure i3 Startup for Work Laptop Display Layout ---
    # Define host-specific i3 startup commands here.
    # These will be MERGED with the startup items defined in home-manager/modules/i3.nix
    # thanks to the Nix/Home Manager module system's list merging.
    xsession.windowManager.i3.config.startup = lib.mkAfter [
      {
        # Use 'exec --no-startup-id' or just 'command' if HM handles exec wrapper
        # Using a direct command string is typical here.
        command = "exec ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1200 --pos 3000x824 --rotate normal --scale 0.5x0.5 --filter nearest --auto --output DP-10 --mode 1920x1080 --pos 0x0 --rotate left   --scale 1x1 --auto --output DP-9 --mode 1920x1080 --pos 1080x420 --rotate normal --scale 1x1 --auto";
        # These settings ensure it runs once at startup and not on i3 reload
        always = false;
        notification = false;
      }
    ];
    xsession.windowManager.i3.config.workspaceOutputAssign = lib.mkOverride 10 [
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
        output = "DP-8";
        workspace = "4";
      }
      {
        output = "DP-8";
        workspace = "5";
      }
      {
        output = "DP-8";
        workspace = "6";
      }
      {
        output = "DP-7";
        workspace = "7";
      }
      {
        output = "DP-7";
        workspace = "8";
      }
      {
        output = "DP-7";
        workspace = "9";
      }
    ];
  };
}
