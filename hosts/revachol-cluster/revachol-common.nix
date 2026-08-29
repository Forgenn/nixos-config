{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:

{
  imports = [
    # Shared Tailscale/subnet-router config (imported by cluster nodes + dolores).
    ../../modules/nixos/tailscale.nix
  ];

  # Previously pinned+compiled a custom 6.17 from source to work around an NFS xattr
  # regression present from 6.12.44 onward (https://bbs.archlinux.org/viewtopic.php?id=307804).
  # `linux_6_16` was removed from nixpkgs (EOL upstream) as of the 26.05 bump, and the fix
  # has since landed upstream in-tree, so just take nixpkgs's default kernel again.
  # boot.kernelPackages left unset = pkgs.linuxPackages (whatever 26.05 ships as current).

  #
  # Shutting down cluster makes pods not shut down correctly
  # removing for now

  # Shut down cluster at 1 in the morning, wake up at certain times depending on the day
  #systemd.services."rtcwake-weekdays" = {
  #  description = "Suspending the system on weekdays";
  #  serviceConfig = {
  #    Type = "oneshot";
  #    ExecStart = "${pkgs.util-linux}/bin/rtcwake -m off -s 19080";
  #  };
  #};
#
#systemd.timers."rtcwake-weekdays" = {
#  description = "Run rtcwake at 1 AM on weekdays";
#  wantedBy = [ "timers.target" ];
#  timerConfig = {
#    OnCalendar = "Mon..Fri 01:00:00";
#    Persistent = true;
#  };
#};
#
#systemd.services."rtcwake-weekends" = {
#  description = "Suspending the system on weekends";
#  serviceConfig = {
#    Type = "oneshot";
#    ExecStart = "${pkgs.util-linux}/bin/rtcwake -m off -s 28800";
#  };
#};
#
#systemd.timers."rtcwake-weekends" = {
#  description = "Run rtcwake at 1 AM on weekends";
#  wantedBy = [ "timers.target" ];
#  timerConfig = {
#    OnCalendar = "Sat,Sun 01:00:00";
#    Persistent = true;
#  };
#};

  # Locale configuration
  i18n = {
    supportedLocales = [
      "en_GB.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Common networking settings
  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [
    22
    6443 # k3s: kube api server
    2379 # k3s, etcd clients
    2380 # k3s, etcd peers
  ];

  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel
  ];

  boot.kernelModules = [
    "ip_vs"
    "ip_vs_rr" # Round Robin scheduler
    "ip_vs_wrr" # Weighted Round Robin scheduler
    "ip_vs_sh" # Source Hashing scheduler
    "nf_conntrack" # Required by IPVS
  ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_filter" = 0;

    "net.ipv4.conf.all.route_localnet" = 1;
    "net.ipv4.conf.enp2s0.route_localnet" = 1; # Also set it on the specific interface

    # Ignore ARP requests for IPs that dont match the receiving interface
    "net.ipv4.conf.enp2s0.arp_ignore" = 1;
    # When sending packets through enp2s0, the sending IP must exist in the interface
    # if not it may use Virtual IP from metallb
    "net.ipv4.conf.enp2s0.arp_announce" = 2;

    # Also good practice for Kubernetes networking in general
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.ipv4.ip_forward" = 1;
  };

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

  age.secrets.infisical_machine_creds_manifest = {
    file = ./secrets/infisical_machine_creds_manifest.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  age.secrets.etcd_s3_backup_manifest = {
    file = ./secrets/etcd_s3_backup_manifest.age;
    mode = "600";
    owner = "ntb";
    group = "users";
  };

  age.secrets.tailscale_authkey = {
    file = ./secrets/tailscale_authkey.age;
    mode = "600";
    owner = "root";
    group = "root";
  };

  programs.nix-ld.enable = true;

  # `nh os switch` instead of `sudo nixos-rebuild switch --flake /etc/nixos#<host>` —
  # nicer diffs, generation cleanup. Flake path matches the fleet convention
  # (every host's checkout now lives at /etc/nixos).
  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo" # ntb user
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOVwSQAPzm403xgtVXkniuc3r8v16l9rFl5CBJH8zZs" # cfv@hatsum
    ];
    #packages = with pkgs; [ ];
  };

  # Dedicated, deliberately non-privileged account for the in-cluster hermes-agent to
  # SSH in as. No wheel, no docker -- key-only auth, no sudo. Can read logs/state, run
  # kubectl (cluster RBAC is separately scoped to read-only via `view`), but can't touch
  # the ZFS pool, can't rebuild NixOS, can't read other users' secrets or root-owned
  # files. Same key across all 3 cluster nodes since it's one logical agent identity.
  users.users.hermes-agent = {
    isNormalUser = true;
    description = "hermes-agent (in-cluster AI agent, restricted)";
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqP4PADPm46nKG42mtxc2tpn4xeuNM9qjW+GWz4qqzT hermes-agent-fleet-ssh"
    ];
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
    # for longhorn
    cryptsetup
    lvm2_vdo
    # nfs test
    acl
    nfs-utils
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  # Important to enable rpcbind for kubernetes NFS PVC mounting
  services.rpcbind.enable = true;

  # Tailnet DNS listener so remote clients (notably Android — which has no OS-level
  # per-domain resolver, so tailscaled's forwarder must dial the nameserver directly,
  # and that dial does not consult subnet routes, see tailscale/tailscale#12027) can
  # resolve the internal zones *.monederobox.dev and *.home. CoreDNS listens on the
  # node's own 100.x tailnet address and forwards the internal zones to the cluster
  # CoreDNS (192.168.1.200), everything else upstream. Point Tailscale split-DNS at
  # THIS node's 100.x tailnet IP.
  services.coredns = {
    enable = true;
    config = let
      # Each cluster node serves its own tailnet (100.x) address.
      tailnetIP = {
        dubois = "100.73.155.27";
        cuno = "100.83.160.122";
        katsuragi = "100.104.15.104";
      }.${config.networking.hostName} or "100.64.0.0";
    in ''
      monederobox.dev:53 home:53 {
        bind ${tailnetIP}
        forward . 192.168.1.200
        cache 30
        errors
      }

      .:53 {
        bind ${tailnetIP}
        forward . 1.1.1.1 9.9.9.9
        cache 300
        errors
      }
    '';
  };

  # CoreDNS must be able to bind its 100.x address before tailscale0 exists at boot,
  # and must only come up after tailscaled assigned the address.
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;
  systemd.services.coredns = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
  # DNS is exposed ONLY on the tailnet interface — not on the LAN/WAN.
  networking.firewall.interfaces."tailscale0" = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };

  # For longhorn
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

  # Longhorn (specifically nsenter) expects the necessary binaries in /bin.
  # so we bind the binaries to path (https://github.com/longhorn/longhorn/issues/2166)
  systemd.services.iscsid.serviceConfig = {
    PrivateMounts = "yes";
    BindPaths = "/run/current-system/sw/bin:/bin";
  };

  # same as above
  systemd.tmpfiles.rules = [
    # Create a symbolic link /usr/bin/mount -> /run/current-system/sw/bin/mount
    "L /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
  ];

  boot.blacklistedKernelModules = [ "nfsv3" ];
  boot.supportedFilesystems = [ "nfs" ];
  services.nfs.settings.nfsd = {
    rdma = false; # Remote Direct Memory Access
    vers3 = false;
    vers4 = false;
    "vers4.0" = false;
    "vers4.1" = false;
    "vers4.2" = true;
  };
  services.nfs.server = {
    enable = false;
  };
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
