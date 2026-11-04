# founding: config.revachol.k3s.founding (see master-k3s-config.nix).
{ founding, ... }:
{
      # If repos public, infisical/eso not needed on bootstrap
      #infisical = {
      #  name = "infisical-standalone";
      #  repo = "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/";
      #  version = "1.5.0";
      #  targetNamespace = "infisical";
      #  createNamespace = true;
      #  hash = "sha256-pASR3xWN6/6MK9KLTIMHvOq0fNjDZLvbWXSN+qSnQEI=";
      #  values = {
      #    infisical = {
      #      image = {
      #        repository = "infisical/infisical";
      #        tag = "v0.131.0-postgres";
      #        pullPolicy = "Always";
      #      };
      #    };
      #    ingress = {
      #      enabled = false;
      #      nginx = {
      #        enabled = false;
      #      };
      #    };
      #  };
      #};

      #eso = {
      #  name = "external-secrets";
      #  repo = "https://charts.external-secrets.io";
      #  version = "0.17.0";
      #  hash = "sha256-+1zkgx7YFiEEeUO4UMBWVF0JU3QaSWsPFjgCPWjZwWI=";
      #  targetNamespace = "external-secrets";
      #  createNamespace = true;
      #};

      # Bootstrap phase only. On a new cluster nothing else can install Argo CD, so the
      # k3s helm-controller does it; from then on Argo CD is self-managed by the
      # gitops-cluster/infra/argocd app (includeCRDs + SSD + full chart ownership), and
      # this release left enabled would be a SECOND owner fighting that app (flapping
      # argocd-cm / argocd-cmd-params-cm / controller rolls). So it follows
      # revachol.k3s.founding: on while founding, off afterwards. Turning it off needs
      # the HelmChart CR's finalizer stripped and the CR deleted first, or helm-controller
      # uninstalls Argo CD -- see docs/runbooks/cluster-nixos-rebuild.md.
      argocd = {
        enable = founding;
        name = "argo-cd";
        repo = "https://argoproj.github.io/argo-helm";
        version = "8.0.16";
        hash = "sha256-TEFNMFuQ+zukQiA1mbGezacLIvPcn2pMqFsDsyifxng=";
        targetNamespace = "argocd";
        createNamespace = true;
        values = {
          # Bootstrap argocd not HA for faster startup
          redis-ha = {
            enabled = true;
          };
        };
      };
}