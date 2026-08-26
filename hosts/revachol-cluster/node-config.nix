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

      # Enable ipvs
      "--kube-proxy-arg=proxy-mode=ipvs"
      "--kube-proxy-arg=ipvs-strict-arp=true"
    ] ++ import ./k3s-leader-election-flags.nix;
  };
}
