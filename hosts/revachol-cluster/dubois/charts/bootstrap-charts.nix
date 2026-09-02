{...}:
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

      # ArgoCD is now fully self-managed by the gitops-cluster/infra/argocd app
      # (includeCRDs + SSD + full chart ownership). Disabling this k3s helm-controller
      # release removes the SECOND owner that was fighting the self-managed app
      # (flapping argocd-cm / argocd-cmd-params-cm / controller rolls). Keep the block
      # as documentation of the original bootstrap; enable=false stops helm-controller
      # from re-installing it. Deliberately NOT deleted so a fresh-cluster rebuild can
      # reference the minimal bootstrap shape (chart, namespace, buildOptions only).
      argocd = {
        enable = false;
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