# Export the versions a node is *actually running*, so a mismatch between a node's
# booted userland and what it was switched to is visible instead of silent.
#
# WHY: on 2026-11-27 a site-wide power event rebooted dubois onto an older
# generation than it had been running. Its iSCSI node records had been written by
# open-iscsi 2.1.13 (the switched-to generation, which was never the boot
# default) and the older iscsiadm on the rebooted node could not parse them
# ("Unknown parameter name node.session.login_redirect_max", exit status 7).
# `iscsiadm` reads the whole /etc/iscsi/nodes database on every call, so every
# Longhorn engine frontend on dubois died and volume attaches failed cluster-wide
# for ~4.5 h. Nothing in the cluster made that mismatch visible beforehand: the
# node looked Ready, and the first symptom was an application crashloop.
#
# The node's effective k3s/open-iscsi/kernel versions follow from *which
# generation it booted*, not from git, so this unit exports both sides:
#
#   node_runtime_info{generation,kernel,k3s,iscsiadm,profile_generation,profile_k3s,profile_iscsiadm} 1
#   node_runtime_profile_mismatch{component="k3s"|"iscsiadm"} 0|1
#   node_generation_booted_differs_from_running 0|1
#   node_generation_running_differs_from_profile 0|1
#
# "profile" is /nix/var/nix/profiles/system: the generation a `nixos-rebuild` last
# switched to. A non-zero mismatch means a rebuild or reboot will change that
# component's version, i.e. the precondition for a write/read format mismatch
# (k3s, open-iscsi) is armed.
#
# Consumed by node-exporter's textfile collector (the DaemonSet reads the host
# root at /host/root; see infra/monitoring/values/values.yaml in gitops-cluster)
# and alerted on by prometheus rule group node-runtime-drift in
# infra/monitoring/node-runtime-drift-alerts.yaml.
#
# WHAT THIS DOES NOT COVER: whether the profile itself is older than what git
# declares. Comparing declared (flake.lock) against booted needs a git-side
# reference; that is the weekly homelab-ops check, not a node metric.
#
# Runbook: docs/runbooks/node-runtime-drift.md
{ pkgs, ... }:

let
  # Where node-exporter's textfile collector reads from on the host.
  textfileDir = "/var/lib/node_exporter/textfile_collector";

  exporter = pkgs.writeShellApplication {
    name = "node-runtime-drift-metrics";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk ];
    text = ''
      set -eu

      out_dir=/var/lib/node_exporter/textfile_collector
      out_file=$out_dir/node_runtime_drift.prom

      running=/run/current-system
      profile=/nix/var/nix/profiles/system
      booted=/run/booted-system

      # k3s --version prints "k3s version v1.35.6+k3s1 (9b0e8f2)".
      k3s_version() {
        if [ -x "$1" ]; then
          "$1" --version 2>/dev/null | awk '/^k3s version/ { print $3; exit }'
        fi
      }

      # iscsiadm --version prints "iscsiadm version 2.1.13".
      iscsiadm_version() {
        if [ -x "$1" ]; then
          "$1" --version 2>/dev/null | awk 'NR == 1 { print $NF; exit }'
        fi
      }

      # Store name of the generation a path resolves to, e.g.
      # nixos-system-dubois-25.11.20260927.3ec6363 -- enough to see a flip.
      generation_of() {
        if [ -e "$1" ]; then
          basename "$(readlink -f "$1")"
        else
          echo missing
        fi
      }

      # 1 when the two paths are not the same store path.
      generation_differs() {
        if [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; then
          echo 0
        else
          echo 1
        fi
      }

      # 1 when the two version strings differ.
      version_differs() {
        if [ "$1" = "$2" ]; then
          echo 0
        else
          echo 1
        fi
      }

      kernel=$(uname -r)

      k3s_run=$(k3s_version "$running/sw/bin/k3s")
      iscsi_run=$(iscsiadm_version "$running/sw/bin/iscsiadm")
      k3s_switched=$(k3s_version "$profile/sw/bin/k3s")
      iscsi_switched=$(iscsiadm_version "$profile/sw/bin/iscsiadm")

      if [ -z "$k3s_run" ]; then k3s_run=missing; fi
      if [ -z "$iscsi_run" ]; then iscsi_run=missing; fi
      if [ -z "$k3s_switched" ]; then k3s_switched=missing; fi
      if [ -z "$iscsi_switched" ]; then iscsi_switched=missing; fi

      gen_run=$(generation_of "$running")
      gen_switched=$(generation_of "$profile")
      gen_booted=$(generation_of "$booted")

      mkdir -p "$out_dir"
      tmp_file=$(mktemp "$out_dir/.node_runtime_drift.XXXXXX")
      trap 'rm -f "$tmp_file"' EXIT

      {
        printf '# HELP node_runtime_info Versions of the userland this node runs, and of the system profile it was switched to.\n'
        printf '# TYPE node_runtime_info gauge\n'
        printf 'node_runtime_info{generation="%s",kernel="%s",k3s="%s",iscsiadm="%s",profile_generation="%s",profile_k3s="%s",profile_iscsiadm="%s"} 1\n' \
          "$gen_run" "$kernel" "$k3s_run" "$iscsi_run" "$gen_switched" "$k3s_switched" "$iscsi_switched"

        printf '# HELP node_runtime_profile_mismatch 1 when the running component differs from the switched profile: a rebuild or reboot will change its version (for open-iscsi that is what armed the 2026-11-27 attach wedge).\n'
        printf '# TYPE node_runtime_profile_mismatch gauge\n'
        printf 'node_runtime_profile_mismatch{component="k3s"} %s\n' "$(version_differs "$k3s_run" "$k3s_switched")"
        printf 'node_runtime_profile_mismatch{component="iscsiadm"} %s\n' "$(version_differs "$iscsi_run" "$iscsi_switched")"

        printf '# HELP node_generation_booted_differs_from_running 1 when /run/booted-system is not the generation active now, i.e. a reboot comes back on a different one.\n'
        printf '# TYPE node_generation_booted_differs_from_running gauge\n'
        printf 'node_generation_booted_differs_from_running %s\n' "$(generation_differs "$booted" "$running")"

        printf '# HELP node_generation_running_differs_from_profile 1 when the active generation is not the switched profile (a switch that was never activated, or a rollback).\n'
        printf '# TYPE node_generation_running_differs_from_profile gauge\n'
        printf 'node_generation_running_differs_from_profile %s\n' "$(generation_differs "$profile" "$running")"
      } > "$tmp_file"

      mv "$tmp_file" "$out_file"
      trap - EXIT

      echo "node-runtime-drift-metrics: generation=$gen_run booted=$gen_booted profile=$gen_switched k3s=$k3s_run (profile $k3s_switched) iscsiadm=$iscsi_run (profile $iscsi_switched)"
    '';
  };
in
{
  # The collector needs the directory to exist; node-exporter cannot create it.
  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
  ];

  systemd.services.node-runtime-drift-metrics = {
    description = "Export node runtime versions (k3s, open-iscsi, generations) for node-exporter";
    # No network, no daemons: pure file writes. Runs as root only because the host
    # path is root-owned.
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${exporter}/bin/node-runtime-drift-metrics";
    };
  };

  systemd.timers.node-runtime-drift-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "node-runtime-drift-metrics.service";
      # Late enough that the boot has settled, and hourly after that so a
      # `nixos-rebuild switch` shows up as a mismatch within the hour.
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
    };
  };
}
