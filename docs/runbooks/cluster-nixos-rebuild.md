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

This sequence never needs dubois's `founding` option. It stays off. For a dubois
that lost its disk, or a cluster built from nothing, see
[dubois: founding a cluster vs rejoining one](#dubois-founding-a-cluster-vs-rejoining-one).

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

## dubois: founding a cluster vs rejoining one

dubois's etcd role is the option `revachol.k3s.founding`
(`hosts/revachol-cluster/dubois/master-k3s-config.nix`), **off by default**:

| `founding` | k3s flags on dubois | bootstrap Argo CD HelmChart |
|---|---|---|
| `false` (default) | `--server https://<joinVia>.home:6443` | not deployed |
| `true` | `--cluster-init` | deployed by the k3s helm-controller |

`revachol.k3s.joinVia` is `cuno` (default) or `katsuragi`.

k3s reads these flags **only while the node's etcd data dir
(`/var/lib/rancher/k3s/server/db`) is empty**. Once it holds an etcd member,
`--cluster-init` and `--server` are both ignored
([k3s docs](https://docs.k3s.io/datastore/ha-embedded#existing-single-node-clusters)).
k3s still tries the `--server` address to reconcile its bootstrap data, and falls
back to its local copy if that server is down. So an ordinary rebuild, the
sequence above, behaves the same either way, and you never touch the option for one.

The flags decide what happens after dubois's disk is wiped or the node is
reinstalled. With `--cluster-init` and an empty data dir, k3s does not rejoin.
It starts a **new, empty single-member cluster** on dubois, and
`api.kube-cluster.revachol.home` resolves to that empty cluster. That is why
`founding` is off except while a cluster is actually being founded.

### Rejoining dubois after a wipe or reinstall

Use this when cuno and katsuragi are running and dubois comes back with no etcd
data. Two of three members keep quorum, so the cluster stays up the whole time.
`api.kube-cluster.revachol.home` points at dubois, so run kubectl on a surviving
server until dubois is back.

1. **Check the survivors.** Both must be Ready:

   ```bash
   ssh cuno 'sudo k3s kubectl get nodes'
   ```

2. **Remove the old dubois from the cluster.** Deleting the Node object makes
   k3s remove its etcd member and its node password secret, so a node with the
   same name can join again
   ([node registration](https://docs.k3s.io/architecture#how-agent-node-registration-works)):

   ```bash
   ssh cuno 'sudo k3s kubectl delete node dubois'
   ```

   Then check that etcd lists exactly two members, cuno and katsuragi:

   ```bash
   ssh cuno 'sudo nix shell nixpkgs#etcd -c etcdctl \
     --endpoints https://127.0.0.1:2379 \
     --cacert /var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
     --cert /var/lib/rancher/k3s/server/tls/etcd/client.crt \
     --key /var/lib/rancher/k3s/server/tls/etcd/client.key \
     member list -w table'
   ```

   If a dubois member is still listed (for example, the Node object was already
   gone), remove it by its ID with `etcdctl ... member remove <id>`, using the
   same flags.

3. **Check the config.** `founding` must be `false` on main, which is the
   default, and `joinVia` must name a member that is Ready (change it to
   `katsuragi` if cuno is the one that is down).

4. **Empty dubois's data dir.** This only matters when dubois was not
   reinstalled from scratch. A leftover `server/db` belongs to the removed
   member, and it would make k3s skip the join:

   ```bash
   ssh dubois 'sudo systemctl stop k3s; sudo mv /var/lib/rancher/k3s/server/db /var/lib/rancher/k3s/server/db.old-$(date +%s)'
   ```

5. **Build and boot.** Use `nixos-install --flake .#dubois` on a reinstall, or
   steps 1 and 3 of the sequence above on an existing system.

6. **Verify that dubois joined and did not found a new cluster.**

   ```bash
   ssh dubois 'journalctl -u k3s -b | grep -E "Managed etcd cluster"'
   ```

   `Managed etcd cluster not yet initialized` means k3s took the join path.
   `Managed etcd cluster initializing` means it founded a new cluster: stop
   k3s, go back to step 3, and repeat from there. Then check `kubectl get nodes`
   (all three Ready, dubois with `control-plane,etcd`) and the member list from
   step 2 (three members, all started). Let Longhorn settle as in step 4 of the
   sequence.

### Founding a new cluster

Only when there is no cluster to join: all three nodes are empty, or you are
deliberately starting over. Founding creates an **empty** cluster. To bring
back the old cluster's state, restore an etcd snapshot
([k3s etcd-snapshot](https://docs.k3s.io/cli/etcd-snapshot#restoring-snapshots))
instead; the snapshots are in S3 (`--etcd-s3`).

1. **Turn founding on.** On main, set `revachol.k3s.founding = true;` in
   `hosts/revachol-cluster/dubois/default.nix`. The nodes build from
   `/etc/nixos` on main.

2. **Found the cluster on dubois.** Build and boot dubois with an empty data dir.
   k3s starts with `--cluster-init`. The helm-controller installs the bootstrap
   Argo CD release (HelmChart `kube-system/argocd`), and the bootstrap
   ApplicationSet (`main-services-set`) points Argo CD at `gitops-cluster`
   `infra/*`. Wait for dubois to be Ready and for the `argocd` pods to run.

3. **Join the other two, one at a time.** katsuragi first, then cuno. Their
   `serverAddr` is `api.kube-cluster.revachol.home`, which is dubois. Wait for
   each to be Ready with `control-plane,etcd` before starting the next.

4. **Wait for Argo CD to manage itself.** The `infra/argocd` Application must be
   Synced and Healthy:

   ```bash
   kubectl -n argocd get application argocd
   ```

   Until then, the helm-controller and Argo CD both own the same release, which
   is why the flip back below is required, not optional.

5. **Turn founding off and hand Argo CD over.** Do it in this order. Deleting
   the HelmChart while it still has its finalizer makes the helm-controller
   uninstall Argo CD. Removing a manifest file does not remove what it created
   ([k3s docs](https://docs.k3s.io/installation/packaged-components)), so the
   CR has to go by hand.

   1. On main, remove the `founding` line again. Stage the build without
      switching:
      `ssh dubois 'cd /etc/nixos && git pull --ff-only && nixos-rebuild boot --flake .#dubois'`.
   2. Remove the bootstrap manifest from the running system, so that k3s does
      not re-create the CR:
      `ssh dubois 'sudo rm /var/lib/rancher/k3s/server/manifests/argocd.yaml'`.
   3. Release the helm-controller's hold, then delete the CR:

      ```bash
      kubectl -n kube-system patch helmchart argocd --type=merge -p '{"metadata":{"finalizers":null}}'
      kubectl -n kube-system delete helmchart argocd
      ```

   4. Reboot dubois as in the sequence above (drain, reboot, verify, uncordon).
      The new generation no longer links `argocd.yaml`. Its `--server` flag is
      ignored because etcd data is now on disk.

6. **Verify the hand-over.** `kubectl -n kube-system get helmchart argocd`
   reports NotFound, the `argocd` Application is still Synced and Healthy, and
   the `argocd` pods were not recreated by an uninstall.

## katsuragi

katsuragi has a DRAM-less ShiJi 512GB NVMe (Maxio controller) with a history of
write timeouts under sustained load, which is what drove the September
incident — SMART was clean; the drive simply could not sustain the writes.
Expect it to be the slowest node to settle, and treat a long rebuild there as
suspicious rather than normal. The open mitigation is the
`nvme_core.default_ps_max_latency_us=0` kernel parameter; replacing the drive
is the real fix.
