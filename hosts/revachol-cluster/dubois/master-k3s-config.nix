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

  bootStrapCharts = import ./charts/bootstrap-charts.nix { inherit pkgs config lib; };
  argocdManifests = import ./manifests/bootstrap-argocd-manifests.nix { inherit pkgs config lib; };
  democraticCsiConfig = import ./manifests/bootstrap-democratic-csi-zfs.nix {
    inherit pkgs config lib; # Pass pkgs for yq
  };
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

  services.k3s = {
    enable = true;
    gracefulNodeShutdown.enable = true;
    # Management AND node
    role = "server";
    tokenFile = config.age.secrets.k3s_token.path;
    clusterInit = true;
    
    extraFlags = [
      "--tls-san=dubois.home,api.kube-cluster.revachol.home"  # The flag
      "--disable=traefik,servicelb"
    ];

    extraKubeProxyConfig = {
      mode = "ipvs";
      ipvs = {
        scheduler = "rr";
        # Setting a timeout of 0 can sometimes help with UDP issues
        udpTimeout = "0s";
      };
    };

    # K3s will write the manifests defined in democraticCsiConfig.manifests
    # to /var/lib/rancher/k3s/server/manifests/.
    # The systemd service above will then attempt to modify one of those files.
    manifests = argocdManifests // democraticCsiConfig.manifests // { 
      traefik = {
        enable = false;
        };
      };

    autoDeployCharts = bootStrapCharts;
  };
}
