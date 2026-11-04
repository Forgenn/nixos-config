{
  pkgs,
  config,
  lib,
  agenix,
  ...
}:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
  # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.1.155";
  kubeMasterHostname = "api.kube-cluster.revachol.home";
  #kubeMasterAPIServerPort = 6443;

  cfg = config.revachol.k3s;
  kubeAPIServerPort = 6443;

  bootStrapCharts = import ./charts/bootstrap-charts.nix {
    inherit pkgs config lib;
    inherit (cfg) founding;
  };
  argocdManifests = import ./manifests/bootstrap-argocd-manifests.nix { inherit pkgs config lib; };
  democraticCsiConfig = import ./manifests/bootstrap-democratic-csi-zfs.nix {
    inherit pkgs config lib; # Pass pkgs for yq
  };
in
{
  # dubois's etcd role. Founding a cluster and joining one are different k3s starts,
  # and k3s only consults them while the node's etcd data dir is empty: once
  # /var/lib/rancher/k3s/server/db holds a member, --cluster-init and --server are both
  # ignored (https://docs.k3s.io/datastore/ha-embedded, "Existing single-node
  # clusters"). With an empty data dir, --cluster-init and no --server starts a NEW
  # single-member cluster -- so a permanent clusterInit = true turned a wiped or
  # reinstalled dubois into a second, empty cluster instead of a returning member
  # (k3s-io/k3s#13623 describes the same split for a removed init node).
  # Procedure for both phases: docs/runbooks/cluster-nixos-rebuild.md.
  options.revachol.k3s = {
    founding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Found a new cluster from dubois: k3s --cluster-init, and the k3s
        helm-controller installs the bootstrap Argo CD release. Only for a cluster
        that does not exist yet; turn it off again once cuno and katsuragi have joined
        and Argo CD manages itself. Off (the default), dubois joins the existing
        cluster through `joinVia`.
      '';
    };
    joinVia = lib.mkOption {
      type = lib.types.enum [
        "cuno"
        "katsuragi"
      ];
      default = "cuno";
      description = ''
        Server dubois joins through when it is not founding. Only read while dubois's
        etcd data dir is empty (a rejoin after a wipe); pick a member that is up.
      '';
    };
  };

  config = {
  # resolve master hostname
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  # packages for administration tasks
  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  systemd.services.democratic-csi-manifest-key-injector = {
    description = "Inject SSH key into Democratic CSI K3s manifest";
    wantedBy = [ "multi-user.target" ]; # Run fairly early
    after = [ "network-online.target" ]; # Ensure agenix ran and network is up (though not strictly needed for local file ops)
    before = [ "k3s.service" ]; # Try to run before k3s fully starts processing manifests

    # Add necessary packages to PATH for the script
    path = [
      pkgs.coreutils-full
      pkgs.gnused
      pkgs.yq
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true; # Important for `before=` ordering if k3s depends on it
      ExecStart = "${democraticCsiConfig.updateManifestScript}/bin/update-csi-manifest-key";
    };
  };

  systemd.services.k3s-secret-symlink = {
    description = "Create symlink for k3s secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ]; # Ensure agenix has decrypted the secret
    before = [ "k3s.service" ]; # Ensure symlink is in place before k3s starts

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-k3s-secret-symlink" ''
        mkdir -p /var/lib/k3s/secrets
        ln -sf ${config.age.secrets.infisical_machine_creds_manifest.path} /var/lib/rancher/k3s/server/manifests/infisical-machine-creds-manifest.yaml
        chown ntb:users /var/lib/rancher/k3s/server/manifests/infisical-machine-creds-manifest.yaml
        chmod 600 /var/lib/rancher/k3s/server/manifests/infisical-machine-creds-manifest.yaml
      '';
    };
  };

  services.k3s = {
    enable = true;
    gracefulNodeShutdown.enable = true;
    # Management AND node
    role = "server";
    tokenFile = config.age.secrets.k3s_token.path;
    # Founding: initialise a new etcd cluster. Otherwise join the existing one through
    # another member -- never through api.kube-cluster.revachol.home, which resolves
    # to dubois itself (see networking.extraHosts above).
    clusterInit = cfg.founding;
    serverAddr = lib.optionalString (!cfg.founding) "https://${cfg.joinVia}.home:${toString kubeAPIServerPort}";

    extraFlags = [
      "--tls-san=dubois.home,api.kube-cluster.revachol.home"  # The flag
      "--disable=traefik,servicelb"

      # k3s does not serve etcd metrics on :2381 at all without this, regardless of how
      # correctly the scrape side (Service/Endpoints/ServiceMonitor) is wired -- see
      # gitops-cluster infra/kube-system-metrics-servicemonitors/kube-etcd.yaml, which
      # points at this port on all 3 server nodes by static IP.
      "--etcd-expose-metrics=true"

      # Enable ipvs
      "--kube-proxy-arg=proxy-mode=ipvs"
      "--kube-proxy-arg=ipvs-strict-arp=true"

      # etcd snapshots were local-disk-only -- offload to the same Hetzner bucket used by
      # every other backup here. Only --etcd-s3 and --etcd-s3-config-secret may be passed
      # on the CLI alongside it -- any other --etcd-s3-* flag on the command line makes
      # k3s ignore the Secret entirely, so bucket/endpoint/folder/creds all live in
      # etcd-s3-backup-manifest.yaml (deployed above) instead. Applies to every server
      # node independently (each takes its own local etcd member snapshot); dubois is
      # also where the Secret gets deployed once, cluster-wide.
      "--etcd-s3"
      "--etcd-s3-config-secret=etcd-s3-backup-config"
      "--etcd-snapshot-schedule-cron=0 */6 * * *"
      "--etcd-snapshot-retention=10"
    ] ++ import ../k3s-leader-election-flags.nix;

    # K3s will write the manifests defined in democraticCsiConfig.manifests
    # to /var/lib/rancher/k3s/server/manifests/.
    # The systemd service above will then attempt to modify one of those files.
    manifests = lib.mkMerge [
    argocdManifests
    democraticCsiConfig.manifests
    {
      traefik.enable = false;
    }
    {
      infisical_machine_creds_manifest = {
        enable = true;
        source = config.age.secrets.infisical_machine_creds_manifest.path;
        target = "infisical_machine_creds_manifest.yaml";
      };
    }
    {
      # etcd snapshots were local-disk-only on each node -- a full node loss lost the
      # snapshot too. Deployed via k3s's own manifest auto-deploy (like infisical's
      # machine creds above) rather than an ArgoCD-managed ExternalSecret deliberately:
      # etcd backup/restore is disaster-recovery tooling and shouldn't depend on the
      # cluster machinery (ArgoCD, ExternalSecrets, Infisical connectivity) it exists to
      # help recover *from*. Same Hetzner bucket/creds used by every other backup in this
      # cluster, just a different folder. See k3s-leader-election-flags.nix's sibling
      # files (master-k3s-config.nix / node-config.nix) for the --etcd-s3* flags that
      # consume this secret.
      etcd_s3_backup_manifest = {
        enable = true;
        source = config.age.secrets.etcd_s3_backup_manifest.path;
        target = "etcd-s3-backup-manifest.yaml";
      };
    }
  ];

    autoDeployCharts = bootStrapCharts;
  };
  };
}
