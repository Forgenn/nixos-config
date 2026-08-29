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
  #
  # NOTE: net.ipv4.ip_forward is NOT set here — it is already defined per-host:
  #   - cluster nodes set boot.kernel.sysctl."net.ipv4.ip_forward" = 1 in revachol-common.nix
  #   - dolores sets it in dolores/default.nix
  # Defining it in this shared module too would collide with those (NixOS: option defined
  # multiple times), so it lives with each host instead.

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
        # Always run `tailscale up` regardless of whether tailscaled is already
        # "Running". Re-running `up` is idempotent and (re)applies the advertised
        # routes + options; the authkey is only consumed on the initial login.
        # Previously this was gated on `status != Running`, but tailscaled usually
        # reaches Running before this oneshot runs, so the --advertise-routes never
        # got applied -> AdvertiseRoutes stayed null and the subnet router was silent
        # despite the build being correct (seen on dolores, 2026-08-29: ip_forward=1
        # but AdvertiseRoutes:null). Guarding on Running created a silent race.
        ${tailscale} up \
          --ssh \
          --advertise-routes=192.168.1.0/24 \
          --accept-dns=false \
          --authkey "file:${config.age.secrets.tailscale_authkey.path}"
      '';
      restartIfChanged = true;
    };
}