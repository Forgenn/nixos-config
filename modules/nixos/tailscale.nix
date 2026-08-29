# Shared Tailscale configuration for the hosts that should behave like WireGuard —
# i.e. reachable from the whole tailnet as if they were physically on the LAN.
#
# Import this from exactly the "4 devices" that must advertise the home LAN subnet:
#   - hosts/revachol-cluster/dubois, cuno, katsuragi (via revachol-common.nix)
#   - hosts/dolores
# It must NOT be added to hosts/common.nix (which every host imports, including the
# desktop/laptop hosts that should not advertise a subnet route).
#
# Each importing host must also define the `tailscale_authkey` agenix secret
# (cluster nodes: revachol-common.nix; dolores: dolores/default.nix).
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --accept-dns=false is deliberate: don't let MagicDNS rewrite resolv.conf on top
  # of the LAN's own CoreDNS .home setup.
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.checkReversePath = "loose"; # tailscale's own recommendation

  # IP forwarding is required for Tailscale to act as a subnet router. Without it a
  # remote client can join the tailnet but has no route back to the LAN, so it is NOT
  # "as if physically present" (e.g. it cannot reach the cluster's 192.168.1.200
  # Envoy/DNS LB from away). Advertising the home subnet makes Tailscale behave like
  # WireGuard: enable it, and you are on the home LAN from anywhere.
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
  };

  systemd.services.tailscale-autoconnect =
    let
      tailscale = "${pkgs.tailscale}/bin/tailscale";
    in
    {
      description = "Automatic connection to Tailscale (subnet router)";
      after = [ "network-online.target" "tailscale.service" ];
      wants = [ "network-online.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        status="$(${tailscale} status --json | ${pkgs.jq}/bin/jq -r .BackendState)"
        if [ "$status" != "Running" ]; then
          ${tailscale} up \
            --ssh \
            --advertise-routes=192.168.1.0/24 \
            --accept-dns=false \
            --authkey "file:${config.age.secrets.tailscale_authkey.path}"
        fi
      '';
      # Always re-run on boot/start so the route re-advertises even if tailscaled
      # is already Running but not yet advertising routes (e.g. after a Tailscale
      # config change or an interrupted first up).
      restartIfChanged = true;
    };
}