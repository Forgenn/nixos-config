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
    #./overlays.nix
    # Nixos modules
    ../../modules/nixos/sunshine.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/chromium.nix
    ../../modules/nixos/hyprland.nix
  ];

  # boot
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  # should set auto snapshots
  boot.zfs.extraPools = [ "zpool" ];
  networking.hostId = "7777a778";
  boot.zfs.devNodes = "/dev/disk/by-id";
  services.zfs.autoScrub.enable = true;

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;


  # Hostname
  networking.hostName = "t440";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

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

      programs.git = {
        enable = true;
        userName = lib.mkDefault "ntb";
        userEmail = lib.mkDefault "ipolmonxammar@gmail.com";
      };

      programs.ssh.extraConfig = ''
        Host github.com
           Hostname github.com
           AddKeysToAgent yes
           IdentityFile  ~/.ssh/id_ed25519
      '';
    };
}
