{
  pkgs,
  config,
  lib,
}:

let
  # You can define your helper functions (like toBase64, fileToBase64) here
  # or pass them in if they are defined in the main file.
  # For simplicity, let's assume they might be needed or you define them here.
  toBase64 =
    str:
    pkgs.runCommand "string-to-base64" { } ''
      echo -n "${str}" | ${pkgs.coreutils-full}/bin/base64 -w0 > $out
    '';

  fileToBase64 =
    filePath:
    pkgs.runCommand "file-to-base64" { } ''
      ${pkgs.coreutils-full}/bin/base64 -w0 ${pkgs.lib.escapeShellArg filePath} > $out
    '';
in
{
  main-services-applicationset = {
    enable = true;
    content = {
      apiVersion = "argoproj.io/v1alpha1";
      kind = "ApplicationSet";
      metadata = {
        name = "main-services-set";
        namespace = "argocd";
      };
      spec = {
        generators = [
          {
            git = {
              repoURL = "https://github.com/Forgenn/gitops-cluster.git";
              revision = "HEAD";
              directories = [
                { path = "infra/*"; }
              ];
            };
          }
        ];
        template = {
          metadata = {
            name = "{{ path.basename }}";
            namespace = "argocd";
            labels = {
              "appset-generated-by" = "main-services-set";
            };
          };
          spec = {
            project = "default";
            source = {
              repoURL = "https://github.com/Forgenn/gitops-cluster.git";
              targetRevision = "HEAD";
              path = "{{ path }}";
            };
            destination = {
              server = "https://kubernetes.default.svc";
              namespace = "{{ path.basename }}";
            };
            syncPolicy = {
              automated = {
                prune = true;
                selfHeal = true;
              };
              syncOptions = [
                "CreateNamespace=true"
                "ServerSideApply=true"
              ];
            };
            ignoreDifferences = [
              {
                group = "apps";
                kind = "Deployment";
                name = "infisical-infisical-standalone-infisical";
                namespace = "infisical";
                jsonPointers = [
                  "/spec/template/metadata/annotations/updatedAt"
                ];
              }
            ];
          };
        };
      };
    };
  };

  argocd-kustomize-options-cm = {
    enable = true;
    content = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "argocd-cm";
        namespace = "argocd";
      };
      data = {
        # This line was already present
        "kustomize.buildOptions" = "--enable-helm";

        # This is the new section to ignore the annotation
        "resource.customizations.ignoreDifferences.apps_Deployment" = ''
          jsonPointers:
          - /spec/template/metadata/annotations/updatedAt
        '';
      };
    };
  };

  argocd-repo-credentials-pat = {
    enable = true;
    content = {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        name = "gitops-repo-credentials-pat";
        namespace = "argocd";
        labels = {
          "argocd.argoproj.io/secret-type" = "repository";
        };
      };
      data = {
        url = builtins.readFile (toBase64 "https://github.com/Forgenn/gitops-cluster");
        # The PAT is used as the password.
        # Not working, not finding /run/agenix secret
        #sshPrivateKey = builtins.readFile (fileToBase64 config.age.secrets.gitops_deploy_key.path);
        # Type of the repository
        type = builtins.readFile (toBase64 "git");
      };
    };
  };
}
