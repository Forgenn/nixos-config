{ pkgs, config, lib, agenix, ... }:
let
  # When using easyCerts=true the IP Address must resolve to the master on creation.
  # So use simply 127.0.0.1 in that case. Otherwise you will have errors like this https://github.com/NixOS/nixpkgs/issues/59364
  kubeMasterIP = "192.168.1.155";
  kubeMasterHostname = "api.kube-cluster.revachol.home";
  #kubeMasterAPIServerPort = 6443;

  # Helper function to base64 encode a string using a derivation
  toBase64 = str: pkgs.runCommand "string-to-base64" {} ''
    echo -n "${str}" | ${pkgs.coreutils-full}/bin/base64 -w0 > $out
  '';

  # Helper function to base64 encode file contents
  fileToBase64 = filePath: pkgs.runCommand "file-to-base64" {} ''
    ${pkgs.coreutils-full}/bin/base64 -w0 ${filePath} > $out
  '';
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

    #manifest = {
    #  argocd-repo-credentials-pat = {
    #    content = {
    #      apiVersion = "v1";
    #      kind = "Secret";
    #      metadata = {
    #        name = "gitops-repo-credentials-pat";
    #        namespace = "argocd";
    #        labels = {
    #          "argocd.argoproj.io/secret-type" = "repository";
    #        };
    #      };
    #      data = {
    #        url = "https://github.com/Forgenn/gitops-cluster";
    #        # The PAT is used as the password.
    #        #password = builtins.readFile (fileToBase64 config.age.secrets.gitops_repo_pat.path);
    #        type = builtins.readFile (toBase64 "git");
    #      };
    #    };
    #  };
    #};

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

      eso = {
        name = "external-secrets";
        repo = "https://charts.external-secrets.io";
        version = "0.17.0";
        hash = "sha256-+1zkgx7YFiEEeUO4UMBWVF0JU3QaSWsPFjgCPWjZwWI=";
        targetNamespace = "external-secrets";
        createNamespace = true;
      };

      argocd = {
        name = "argo-cd";
        repo = "https://argoproj.github.io/argo-helm";
        version = "8.0.14";
        hash = "sha256-7woJUYBN724uMvhH73EeYIcCvb3/vawUmvrWsgVhkGQ=";
        targetNamespace = "argocd";
        createNamespace = true;
        values = {
          # Bootstrap argocd not HA for faster startup
          redis-ha = {
            enabled = false;
          };
        };
      };
    };
  };
}
