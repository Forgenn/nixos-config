{ pkgs, config, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
  # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.1.155";
  kubeMasterHostname = "api.kube-cluster.revachol.home";
  kubeMasterAPIServerPort = 6443;
in
{
  # resolve master hostname
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  # packages for administration tasks
  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  services.k3s = {
    enable = true;
    # HA conversion: was "agent" (worker-only). Now "server" with no clusterInit (that's
    # dubois's job, see master-k3s-config.nix) and serverAddr pointing at the existing
    # cluster -- k3s's built-in join mechanism handles etcd membership automatically, no
    # manual etcd surgery. Root motivation: dubois's single-member etcd meant its own
    # disk stalls could take down the whole apiserver; a real 3-member quorum means a
    # write only needs 2-of-3 acks, so one slow member (dubois) no longer single-handedly
    # blocks the cluster the way it did before.
    role = "server";
    tokenFile = config.age.secrets.k3s_token.path;
    serverAddr = "https://" + kubeMasterHostname + ":" + (builtins.toString kubeMasterAPIServerPort);
    extraFlags = [
      "--tls-san=${config.networking.hostName}.home,${kubeMasterHostname}"

      # Was missing here despite being on dubois's master-k3s-config.nix -- as an agent,
      # traefik/servicelb never mattered (server-only addons), but now that this node is
      # a server too, k3s's own manifest auto-deploy tried to reintroduce them
      # independently, causing helm-install-traefik CrashLoopBackOff cluster-wide right
      # after the HA join (missing CRDs, since the real disable was never propagated here).
      "--disable=traefik,servicelb"

      # k3s does not serve etcd metrics on :2381 at all without this, regardless of how
      # correctly the scrape side (Service/Endpoints/ServiceMonitor) is wired -- see
      # gitops-cluster infra/kube-system-metrics-servicemonitors/kube-etcd.yaml, which
      # points at this port on all 3 server nodes by static IP.
      "--etcd-expose-metrics=true"

      # Enable ipvs
      "--kube-proxy-arg=proxy-mode=ipvs"
      "--kube-proxy-arg=ipvs-strict-arp=true"

      # etcd-s3-backup-config Secret is deployed once (cluster-wide) via dubois's k3s
      # manifest auto-deploy -- see master-k3s-config.nix for the full explanation and
      # secret provenance. Same flags here so this node's own local etcd member also
      # snapshots to S3 independently.
      "--etcd-s3"
      "--etcd-s3-config-secret=etcd-s3-backup-config"
      "--etcd-snapshot-schedule-cron=0 */6 * * *"
      "--etcd-snapshot-retention=10"
    ] ++ import ./k3s-leader-election-flags.nix;
  };
}
