# Rebuilding the Revachol cluster nodes

Deploys are deliberately manual. Nothing in CI or the `homelab-ops` bot ever
runs `nixos-rebuild` — the bot merges a `flake.lock` bump at most, and even that
is disabled for this repo. Applying it is your decision.

**Why this exists.** The 2026-09-19 incident began with the three nodes 24 days
adrift: booted on 25.05 while the flake said 26.05. A drifted node is a node
whose behaviour nobody can predict from the repo, and the rebuild that would
have closed the gap had never been run.

## Before you start

The cluster track moves on its own schedule now (`nixpkgs-cluster`, monthly,
14-day soak). A cluster bump carries **k3s itself and the node kernel** —
nothing pins k3s independently of nixpkgs. Read the `dry-run` comment on the
Renovate PR before merging it: that fetch list names what actually moves.

Check the current gap on each node:

```bash
ssh dubois 'readlink -f /run/current-system; readlink -f /run/booted-system'
```

If those differ, the node has been rebuilt but not rebooted — it is running
older code than it is configured for. That is the drift that hurt in September.

## The sequence

**One node at a time. Always.** Three nodes are all control-plane and all etcd
members; losing two at once loses quorum.

Order: `katsuragi` → `cuno` → `dubois`. dubois is the control plane you reach
the cluster through, so it goes last — if an earlier node breaks, you still
have a working entry point.

For each node:

1. **Pull and build, don't switch.**

   ```bash
   ssh <node> 'cd /etc/nixos && git pull --ff-only && nixos-rebuild boot --flake .#<node>'
   ```

   `boot`, not `switch`: it stages the new generation for next boot without
   restarting services under a live etcd member. A `switch` can restart
   networking or containerd beneath a running k3s.

2. **Drain.**

   ```bash
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
   ```

3. **Reboot and wait.**

   ```bash
   ssh <node> 'sudo reboot'
   kubectl get nodes -w
   ```

4. **Verify before touching the next node.** All three must be true:

   ```bash
   kubectl get nodes                      # every node Ready
   kubectl -n kube-system get pods        # no CrashLoopBackOff
   ssh <node> 'sudo k3s kubectl get --raw /readyz?verbose'
   ```

   Longhorn also needs to settle — replicas rebuild after a node returns:

   ```bash
   kubectl -n longhorn-system get volumes.longhorn.io -o wide | grep -v healthy
   ```

   Wait for that to come back empty. Rebooting the next node while replicas
   are still rebuilding is how a rebuild storm starts: that feedback loop is
   what turned one bad disk into a cluster-wide outage in September.

5. **Uncordon.**

   ```bash
   kubectl uncordon <node>
   ```

Only then move to the next node.

## Rolling back

Every rebuild leaves the previous generation in the bootloader. If a node comes
back broken, reboot and pick the previous entry from the systemd-boot menu —
that is the fastest recovery and it needs no working network on the node.

To roll back deliberately once you are in:

```bash
ssh <node> 'sudo nixos-rebuild switch --rollback'
```

## katsuragi

katsuragi has a DRAM-less ShiJi 512GB NVMe (Maxio controller) with a history of
write timeouts under sustained load, which is what drove the September
incident — SMART was clean; the drive simply could not sustain the writes.
Expect it to be the slowest node to settle, and treat a long rebuild there as
suspicious rather than normal. The open mitigation is the
`nvme_core.default_ps_max_latency_us=0` kernel parameter; replacing the drive
is the real fix.
