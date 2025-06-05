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

  ########################################################################
  # --- Sunshine config ---
  ########################################################################
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

  ########################################################################
  # --- KDE config ---
  ########################################################################
  programs.kdeconnect.enable = true;

  ########################################################################
  # --- Chromium config ---
  ########################################################################
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = lib.mkDefault pkgs.kdePackages.plasma-browser-integration;
  };

  services.openssh.settings.X11Forwarding = true;

  programs.ssh = {
    startAgent = lib.mkOverride 10 true;
  };

  ########################################################################
  # --- Home-manager config ---
  ########################################################################
  home-manager.users.${user} = {

    ########################################################################
    # --- Cursor config ---
    ########################################################################
    programs.vscode = {
      enable = true;
      package = pkgs.code-cursor;
      #mutableExtensionsDir = true;
      profiles.default = {
        userSettings = {
          "editor.cursorBlinking" = "smooth";
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "window.commandCenter" = true;
          #"workbench.colorTheme" = "SynthWave '84";
          #"workbench.colorTheme" = "Monokai Pro (Filter Spectrum)";
          "workbench.colorTheme" = "Tokyo Night Storm";
          "workbench.tree.indent" = 24;
          "git.autofetch" = true;
          "vs-kubernetes" = {
            "vs-kubernetes.crd-code-completion" = "enabled";
          };
          "terminal.external.linuxExec" = "ghostty";
          "terminal.integrated.defaultProfile.linux" = "fish";
          "editor.fontFamily" = "'Fira Code Symbol'";
          "editor.inlayHints.fontFamily" = "Fira Code SymbolSymbol";
          "editor.codeLensFontFamily" = "Fira Code Symbol";
          "editor.inlineSuggest.fontFamily" = "Fira Code";
          "terminal.integrated.fontFamily" = "'Fira Code', 'Fira Code Symbol'";
          "docker.extension.experimental.composeCompletions" = true;
          "workbench.activityBar.orientation" = "vertical";
        };

        extensions = with pkgs.vscode-extensions; [
          golang.go
          matangover.mypy
          redhat.vscode-yaml
          charliermarsh.ruff
          ms-python.python
          jnoortheen.nix-ide
          vscodevim.vim
          enkia.tokyo-night
          # Unavaible nixos, install
          #monokai.theme-monokai-pro-vscode
        ];
      };
    };

    ########################################################################
    # --- SSH config ---
    ########################################################################
    services.ssh-agent = {
      enable = true;
    };

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''

        Host github.com
           Hostname github.com
           AddKeysToAgent yes
           IdentityFile  ~/.ssh/id_ed25519_ais

        Host p.github.com
           AddKeysToAgent no
           Hostname github.com
           IdentitiesOnly no
           IdentityFile  ~/.ssh/id_ed25519

        Host gitlab.com
          AddKeysToAgent yes
          Hostname gitlab.com
          IdentitiesOnly yes
          IdentityFile  ~/.ssh/id_ed25519_ais
          
        Host bitbucket.org
          AddKeysToAgent yes
          Hostname bitbucket.org
          IdentitiesOnly yes
          IdentityFile  ~/.ssh/id_ed25519_ais
      '';
    };
    ########################################################################
    # --- Git config ---
    ########################################################################
    programs.git = {
      # Use lib.mkOverride to ensure these values take precedence over
      # any potential definitions in home.nix or common.nix.
      # Priority 10 is a common choice for overrides.
      userName = lib.mkOverride 10 "ntb";
      userEmail = lib.mkOverride 10 "pol.monedero@aistechspace.com";
    };
    ########################################################################
    # --- Configure i3 Startup for Work Laptop Display Layout ---
    ########################################################################
    # Define host-specific i3 startup commands here.
    # These will be MERGED with the startup items defined in home-manager/modules/i3.nix
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
