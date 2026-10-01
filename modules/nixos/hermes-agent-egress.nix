# The in-cluster hermes-agent SSHes in as `hermes-agent` and may run any command
# (free-form diagnostics), but from here it may not open connections to what the
# pod's own egress NetworkPolicy keeps it from (gitops-cluster
# infra/hermes-agent/network-policy-egress.yaml): pods and services (kube-router
# always admits a node's own traffic to its pods, so the unauthenticated Longhorn
# manager API would be one curl away), the tailnet, the client LAN, and the
# server LAN's admin interfaces (switches, JetKVM). Allowed on the server LAN:
# the cluster nodes, dolores, and MetalLB's pool -- same as the pod.
#
# The rules sit in the raw table: on cluster nodes the filter table belongs to
# k3s/kube-router, whose local-node ACCEPT would win over anything after it. raw
# cannot REJECT, so blocked connections time out.
{ config, ... }:
let
  ipt = "${config.networking.firewall.package}/bin/iptables -w";
  ip6t = "${config.networking.firewall.package}/bin/ip6tables -w";
  chain = "HERMES-AGENT-OUT";
  allow = [ "192.168.1.155" "192.168.1.156" "192.168.1.157" "192.168.1.34" ];
  block = [ "10.42.0.0/16" "10.43.0.0/16" "100.64.0.0/10" "192.168.0.0/24" "192.168.1.0/24" ];
in
{
  systemd.services.hermes-agent-egress = {
    description = "Limit where the hermes-agent user can open connections";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      for t in "${ipt}" "${ip6t}"; do
        $t -t raw -N ${chain} 2>/dev/null || $t -t raw -F ${chain}
      done
      ${builtins.concatStringsSep "\n" (map (a: "${ipt} -t raw -A ${chain} -d ${a}/32 -j RETURN") allow)}
      ${ipt} -t raw -A ${chain} -m iprange --dst-range 192.168.1.200-192.168.1.250 -j RETURN
      ${builtins.concatStringsSep "\n" (map (c: "${ipt} -t raw -A ${chain} -d ${c} -j DROP") block)}
      ${ip6t} -t raw -A ${chain} -d fd7a:115c:a1e0::/48 -j DROP
      for t in "${ipt}" "${ip6t}"; do
        $t -t raw -C OUTPUT -m owner --uid-owner hermes-agent -j ${chain} 2>/dev/null \
          || $t -t raw -I OUTPUT 1 -m owner --uid-owner hermes-agent -j ${chain}
      done
    '';
    preStop = ''
      for t in "${ipt}" "${ip6t}"; do
        $t -t raw -D OUTPUT -m owner --uid-owner hermes-agent -j ${chain} 2>/dev/null || true
        $t -t raw -F ${chain} 2>/dev/null || true
        $t -t raw -X ${chain} 2>/dev/null || true
      done
    '';
  };
}
