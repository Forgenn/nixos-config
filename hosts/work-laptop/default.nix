# hosts/laptop/default.nix
{
  config,
  pkgs,
  lib,
  inputs,
  user,
  cursorOverlayFile,
  customOpensshOverlayFile,
  opensshDontCheckPermPatch,
  ...
}: # Note the 'user' arg passed from flake.nix

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./overlays.nix
    ./programs-config.nix
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
    slack
    #overlay
    code-cursor
    pkgs.unstable.openbao
    # Home integrations
    pkgs.unstable.deskflow
    sunshine
    # Programming things
    uv
    python312
    python313
    buf
    mypy
    go
    nodejs_24
    postman
    jq
    vscode
    ghostty
    starship
    nixfmt-rfc-style
    nil
    # GCP things
    opentofu
    kubernetes-helm
    google-cloud-sdk
    k9s
    kubectl
    (pkgs.google-cloud-sdk.withExtraComponents [
      pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    #Kde things
    kdePackages.powerdevil
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.plasma-thunderbolt
  ];
}
