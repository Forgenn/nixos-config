{ pkgs, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
  # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.1.155";
  kubeMasterHostname = "api.kube-cluster.revachol.home";
  #kubeMasterAPIServerPort = 6443;
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
    tokenFile = ../secrets/k3s_token.age;
    clusterInit = true;
    extraFlags = [
      "--tls-san dubois.home  api.kube-cluster.revachol.home"
      "--disable traefik nginx"
    ];

    autoDeployCharts = {
      infisical = {
        name = "infisical-standalone";
        repo = "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/";
        version = "1.5.0";
        targetNamespace = "infisical";
        createNamespace = true;
        hash = "sha256-pASR3xWN6/6MK9KLTIMHvOq0fNjDZLvbWXSN+qSnQEI=";
        values = {
          infisical = {
            image = {
              repository = "infisical/infisical";
              tag = "v0.131.0-postgres";
              pullPolicy = "Always";
            };
          };
          ingress = {
            enabled = false;
            nginx = {
              enabled = false;
            };
          };
        };
      };
    };
  };
}
