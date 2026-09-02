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
                # Without this, selfHeal reverts fields that ignoreDifferences tells
                # ArgoCD to ignore: the CNPG/ESO operators rewrite their CRs' status +
                # annotations, ArgoCD self-heals them back, loop forever -> the 5 DB apps
                # (infisical, pocket-id, sparky-fitness, vaultwarden, hermes-agent) stay
                # OutOfSync despite being Healthy and their drift being ignored. Respect
                # the ignoreDifferences at sync time so self-heal stops fighting them.
                "RespectIgnoreDifferences=true"
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
              {
                group = "external-secrets.io";
                kind = "ExternalSecret";
                # The old top-level /spec/conversionStrategy etc. paths are inert (in
                # external-secrets.io/v1 those live under .spec.data[].remoteRef.*, not
                # top-level spec). hermes-agent now materializes them in git. What ESO
                # actually rewrites on the CR is status + annotations; ignore those so
                # ExternalSecrets reconcile without hiding real spec/data changes.
                jqPathExpressions = [
                  ".status"
                  ".metadata.annotations"
                ];
              }
              {
                # StatefulSets server-side-default volumeClaimTemplates[].status.phase
                # and .volumeMode, which git never specifies -- classic ArgoCD SSA diff
                # that kept zot, karakeep, pocket-id, infisical (redis), and seaweedfs
                # permanently OutOfSync despite being genuinely healthy and in sync.
                # Applied live via `kubectl patch applicationset` first (Opus 5 audit
                # finding, 2026-08-27); mirrored here so it survives the next switch.
                group = "apps";
                kind = "StatefulSet";
                jsonPointers = [
                  "/spec/volumeClaimTemplates"
                ];
              }
              {
                # CNPG operator (admission webhook) defaults many Cluster spec fields at
                # apply time that git never declares (enablePDB, failoverDelay, monitoring,
                # postgresUID/GID, primaryUpdateMethod, probes, replicationSlots,
                # smartShutdownTimeout, startDelay/stopDelay, switchoverDelay, bootstrap,
                # affinity, logLevel, maxSyncReplicas/minSyncReplicas, imageName, ...).
                # ArgoCD compares bare git YAML vs the fully-populated live object, so every
                # webhook-defaulted field reads as drift -> the CNPG-backed apps stay
                # OutOfSync despite being Healthy and correctly synced. Ignore status AND
                # these operator-defaulted spec fields. Real user-set config (instances,
                # resources, storage, backup) is NOT ignored, so genuine drift still surfaces.
                group = "postgresql.cnpg.io";
                kind = "Cluster";
                jsonPointers = [
                  "/status"
                  "/metadata/annotations"
                  "/spec/affinity"
                  "/spec/bootstrap"
                  "/spec/enablePDB"
                  "/spec/enableSuperuserAccess"
                  "/spec/failoverDelay"
                  "/spec/imageName"
                  "/spec/logLevel"
                  "/spec/maxSyncReplicas"
                  "/spec/minSyncReplicas"
                  "/spec/monitoring"
                  "/spec/postgresGID"
                  "/spec/postgresUID"
                  "/spec/postgresql"
                  "/spec/primaryUpdateMethod"
                  "/spec/primaryUpdateStrategy"
                  "/spec/probes"
                  "/spec/replicationSlots"
                  "/spec/smartShutdownTimeout"
                  "/spec/startDelay"
                  "/spec/stopDelay"
                  "/spec/switchoverDelay"
                ];
              }
              {
                # ESO-managed Secret: the operator rewrites annotations after ArgoCD
                # applies it. Scoped to the specific vaultwarden secret by name+namespace
                # and ignores ONLY annotations (NOT .data) so a rotated credential in git
                # still applies. A kind-wide unnamed /data ignore would silently never
                # write Secret data on any app — avoid that (audit constraint).
                group = "";
                kind = "Secret";
                name = "vaultwarden-secrets";
                namespace = "vaultwarden";
                jqPathExpressions = [
                  ".metadata.annotations"
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

  kube-system-etcd-endpoints = {
    enable = true;
    # ArgoCD's argocd-cm ships (via the argo-helm chart's own defaults, not anything set
    # in this repo) a hardcoded `resource.exclusions` list that drops Endpoints and
    # EndpointSlice from every Application cluster-wide, to cut watch noise -- confirmed
    # live: gitops-cluster's infra/kube-system-metrics-servicemonitors/kube-etcd.yaml
    # defines a plain Endpoints object alongside its Service/ServiceMonitor, and ArgoCD's
    # own sync result silently omits it (Service + both ServiceMonitors apply cleanly,
    # Endpoints never appears in the result at all -- not an error, just excluded).
    # Deployed here instead via k3s's manifest auto-deploy, the same mechanism already
    # used for etcd_s3_backup_manifest/infisical_machine_creds_manifest in
    # master-k3s-config.nix for the same class of reason: cluster plumbing that
    # ArgoCD structurally cannot own. Static 3-node IP list, not label-selector-based
    # (k3s's embedded etcd isn't a selectable pod), so this only needs to exist once,
    # cluster-wide -- deployed from dubois (the clusterInit node) like the other two.
    content = {
      apiVersion = "v1";
      kind = "Endpoints";
      metadata = {
        name = "kube-system-etcd";
        namespace = "kube-system";
        labels = {
          "k8s-app" = "etcd-server";
        };
      };
      subsets = [
        {
          addresses = [
            { ip = "192.168.1.155"; } # dubois
            { ip = "192.168.1.156"; } # cuno
            { ip = "192.168.1.157"; } # katsuragi
          ];
          ports = [
            {
              name = "http-metrics";
              port = 2381;
              protocol = "TCP";
            }
          ];
        }
      ];
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
