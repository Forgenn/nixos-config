# Node runtime drift (which userland a node is actually running)

A node's effective tool versions — k3s, open-iscsi, kernel — follow from **which
NixOS generation it booted**, not from what `flake.lock` declares. This runbook
covers the metric that makes that visible, and what to do when it fires.

**Why it exists.** On 2026-11-27 a site-wide power event rebooted dubois onto an
older generation than it had been running. Its iSCSI node records had been written
by open-iscsi **2.1.13** (the generation it had been switched to, which never
became the boot default) and the older `iscsiadm` (**2.1.12**) on the rebooted node
could not parse them — open-iscsi changes session parameter names in patch
releases, and `iscsiadm` reads the whole `/etc/iscsi/nodes` database on every call.
Result: every Longhorn engine frontend on dubois failed (`failed to start up
frontend`, exit status 7), volumes whose engine lived there could not attach, and
the cluster spent ~4.5 h degraded. Nothing made the drift visible beforehand: the
node reported `Ready`, and the first symptom was an application crashloop in
`infisical`. Same class as k3s coming back as 1.35.6 on a node that had been
running 1.35.8.

## What is exported

`modules/nixos/node-runtime-drift-metrics.nix` runs
`node-runtime-drift-metrics.service` (boot + every hour) and writes
`/var/lib/node_exporter/textfile_collector/node_runtime_drift.prom` on the host,
which the node-exporter DaemonSet reads through its `/host/root` mount:

| metric | meaning |
| --- | --- |
| `node_runtime_info{generation,kernel,k3s,iscsiadm,profile_generation,profile_k3s,profile_iscsiadm}` | what is running now, and what the switched profile (`/nix/var/nix/profiles/system`) holds |
| `node_runtime_profile_mismatch{component="k3s"\|"iscsiadm"}` | `1` when running ≠ switched profile for that component: a rebuild **or a reboot** will change its version. This is the precondition for a write/read format mismatch |
| `node_generation_booted_differs_from_running` | `1` when a reboot would come back on a different generation than the one active now |
| `node_generation_running_differs_from_profile` | `1` when the active generation is not the switched profile (a switch never activated, or a rollback). Exactly dubois's state before the reboot |

Alerting lives in `gitops-cluster`, `infra/monitoring/node-runtime-drift-alerts.yaml`
(group `node-runtime-drift`): `NodeRuntimeProfileMismatch`, `NodeRuntimeMismatch`
(cross-node disagreement) and `NodeRuntimeMetricsAbsent`.

## When it fires

```bash
# what each node runs vs what it was switched to
ssh <node> 'iscsiadm --version; readlink -f /run/current-system /run/booted-system /nix/var/nix/profiles/system'
ssh <node> 'journalctl -u node-runtime-drift-metrics -n 5 --no-pager'   # the unit logs both sides
```

* `node_runtime_profile_mismatch{component="iscsiadm"} == 1` — the disagreeing
  pair is exactly the one that costs a node all attaches after a reboot. Rebuild
  **and reboot** the node per `docs/runbooks/cluster-nixos-rebuild.md` so the new
  generation becomes the boot default; the reboot is what closes it, and doing it
  deliberately is far cheaper than having a power cut do it.
* `node_generation_running_differs_from_profile == 1` — the node is running an
  older generation than it was switched to. Same remedy.
* `NodeRuntimeMismatch` — nodes disagree with each other on k3s/open-iscsi. All
  three should be on the same lock; rebuild the odd one out.

Clearing the iSCSI records (`rm -rf /etc/iscsi/nodes/*`) is the *repair* once a
node is already wedged; it is not a substitute for rebuilding, which is what
removes the drift. See also `docs/runbooks/iscsi-node-records.md`.

## What this does not cover

* **Profile vs git.** The metric compares the node against its own switched
  profile. Whether that profile is older than `flake.lock` is a git-side question
  (the weekly homelab-ops drift check compares the declared k3s/open-iscsi
  versions against what the nodes report).
* **A rollback while `iscsid` keeps running.** `iscsid` holds mount-namespace
  binds into the generation it started under, so a `iscsiadm` resolved through
  `/bin` can be older than the one under `/usr/bin`. The metric reports the
  generation the node booted; that in-boot skew is not represented, and is one
  more reason to reboot deliberately rather than switch in place.
