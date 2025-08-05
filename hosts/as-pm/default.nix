# hosts/laptop/default.nix
{
  config,
  pkgs,
  lib,
  inputs,
  user,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./overlays.nix
    # Nixos modules
    ../../modules/nixos/sunshine.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/chromium.nix
    ../../modules/nixos/hyprland.nix
  ];

  # Hostname
  networking.hostName = "as-pm";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Install Bolt Daemon
  services.hardware.bolt.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable KDE connect
  programs.kdeconnect.enable = true;

  # Enable ssh
  services.openssh.settings.X11Forwarding = true;
  programs.ssh.startAgent = lib.mkOverride 10 true;

  services.upower.enable = true;
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;

  # Define the primary user account on this system
  users.users.${user} = {
    isNormalUser = true;
    description = "ntb";
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ]; # 'wheel' for sudo access
    initialHashedPassword = "*"; # Set a password manually or use home-manager/impermanence
    openssh.authorizedKeys.keys = [
      # Add your SSH public key(s) here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo"
    ];
  };

  security.sudo.wheelNeedsPassword = true; # Or true if you prefer

  # Firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
  ];

  # Needed to make some programs work (remote vscode)
  programs.nix-ld.enable = true;

  # Laptop specific packages (less common, prefer home-manager)
  environment.systemPackages = with pkgs; [
    # General
    pkgs.chromium
    #Kde things
    kdePackages.powerdevil
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.plasma-thunderbolt
  ];

  home-manager.users.${user} =
    {
      pkgs,
      lib,
      self,
      ...
    }:
    {
      imports = [
        (self + "/modules/home-manager/base.nix")
        (self + "/modules/home-manager/i3.nix")
        (self + "/modules/home-manager/cursor.nix")
      ];

      home.packages = with pkgs; [
        slack
        postman
        ghostty
        starship
        code-cursor
        zed-editor
        vscode
        pkgs.unstable.deskflow
        uv
        python313
        buf
        mypy
        go
        nodejs_24
        jq
        nixfmt-rfc-style
        nil
        opentofu
        kubernetes-helm
        k9s
        kubectl
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
        pkgs.unstable.openbao
        gh
        gemini-cli
        claude-code
        bitwarden-desktop
        x2goclient
      ];

      xsession.windowManager.i3.config = lib.mkMerge [
        {
          startup = [
            {
              command = "exec ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1200 --pos 3000x824 --rotate normal --scale 0.5x0.5 --filter nearest --auto --output DP-10 --mode 1920x1080 --pos 0x0 --rotate left   --scale 1x1 --auto --output DP-9 --mode 1920x1080 --pos 1080x420 --rotate normal --scale 1x1 --auto";
              always = false;
              notification = false;
            }
          ];
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
        }
      ];

      programs.ssh.extraConfig = ''
        Host github.com
           Hostname github.com
           AddKeysToAgent yes
           IdentityFile  ~/.ssh/id_ed25519_ais

        Host p.github.com
           AddKeysToAgent no
           Hostname github.com
           IdentitiesOnly no
           IdentityAgent none
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
          IdentityFile  ~/.ssh/id_ed25519_bitbucket

        Host compilaistron.wks.aistech
          User pol

      '';
    };
}
