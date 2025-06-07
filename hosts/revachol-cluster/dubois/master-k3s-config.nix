{ pkgs, config, lib, agenix, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
  # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.1.155";
  kubeMasterHostname = "api.kube-cluster.revachol.home";
  #kubeMasterAPIServerPort = 6443;

  # Import needed bootstraping manifests/charts from other files
  argocdManifests = import ./manifests/bootstrap-argocd-manifests.nix { 
    inherit pkgs config lib;
  };

  bootStrapCharts = import ./charts/bootstrap-charts.nix {};
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
    # Management AND node
    role = "server";
    tokenFile = config.age.secrets.k3s_token.path;
    clusterInit = true;
    extraFlags = [
      "--tls-san dubois.home api.kube-cluster.revachol.home"
      "--disable traefik nginx"
    ];

    manifests = argocdManifests;
    
    autoDeployCharts = bootStrapCharts;
  };
}
