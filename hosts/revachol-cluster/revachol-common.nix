{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:

{
  imports = [ ];

  # Locale configuration
  i18n = {
    supportedLocales = [
      "en_GB.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Common networking settings
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    6443 # k3s: kube api server
    2379 # k3s, etcd clients
    2380 # k3s, etcd peers
  ];

  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel
  ];

  # Enable agenix
  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secretsDir = "/run/agenix";
  };

  age.secrets.github_node_key = {
    file = ./secrets/github_node_key.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  age.secrets.k3s_token = {
    file = ./secrets/k3s_token.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  age.secrets.nas_node_key = {
    file = ./secrets/nas_node_key.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  age.secrets.gitops_deploy_key = {
    file = ./secrets/gitops_deploy_key.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  programs.nix-ld.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Configure console keymap
  console.keyMap = "uk";

  users.users.${user} = {
    isNormalUser = true;
    description = "Cluster User";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo"
    ];
    #packages = with pkgs; [ ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    tmux
    tcpdump
    # install agenix defined in flake
    inputs.agenix.packages.${pkgs.system}.default
    nixd
    nixfmt-rfc-style
    kubernetes-helm
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  # Important to enable rpcbind for kubernetes NFS PVC mounting
  services.rpcbind.enable = true;

  # Configure git to use the decrypted github_node_key for SSH
  programs.ssh = {
    extraConfig = ''
      Host github.com
            AddKeysToAgent yes
            Hostname github.com
            IdentitiesOnly yes
            IdentityFile  ${config.age.secrets.github_node_key.path}
      Host dolores.home
            AddKeysToAgent yes
            Hostname dolores.home
            IdentitiesOnly yes
            IdentityFile  ${config.age.secrets.nas_node_key.path}
    '';
  };

  home-manager.users.${user} = {
    programs.git = {
      enable = true;
      userName = lib.mkOverride 10 "ntb";
      userEmail = lib.mkOverride 10 "ipolmonxammar@gmail.com";
      extraConfig = {
        "safe" = {
          directory = "/etc/nixos";
        };
      };
    };
  };

  # Common security settings
  security.sudo.wheelNeedsPassword = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
