# iSCSI node records on the cluster nodes

Longhorn attaches a volume by logging the node in as an iSCSI initiator. The
result is a *node record* under `/etc/iscsi/nodes/iqn.2019-10.io.longhorn:pvc-…/`.
Those records are cache, but they are version-specific: open-iscsi changes
parameter names in patch releases, and a record that names a parameter the local
`iscsiadm` does not know makes `iscsiadm` reject the **whole database**, not
just that record.

## Symptom

One node cannot attach *anything* after a reboot, and pods on the other nodes
whose volume engine lives there stall too (FailedAttachVolume / "is not ready
for workloads"). In the instance-manager log on the affected node:

```
failed to start up frontend: Failed to get node.session.scan mode: failed to execute:
/usr/bin/nsenter [nsenter --mount=/host/proc/1/ns/mnt --net=/host/proc/1/ns/net iscsiadm
-m node -T iqn.2019-10.io.longhorn:pvc-… -p 10.42.0.116 -o show], output ,
stderr iSCSI ERROR: Unknown parameter name node.session.login_redirect_max
iSCSI ERROR: config file /etc/iscsi/nodes/iqn.2019-10.io.longhorn:pvc-…/10.42.0.116,3260,1/default invalid.
… exit status 7
```

Roughly two of these per volume every 15 s. `longhorn-manager` runs the **host's**
`iscsiadm` (`nsenter` into PID 1's namespaces — its own image installs no
open-iscsi), so this is not a Longhorn version problem, and it is not per volume.

## Diagnose (read-only)

```bash
ssh <node> 'iscsiadm --version'
ssh <node> 'iscsiadm -m node -o show >/dev/null; echo "exit=$?"'   # 7 == database unreadable
ssh <node> 'grep -rlE "conn_reopen_log_freq|login_redirect_max" /etc/iscsi/nodes | head'
ssh <node> 'readlink -f /run/current-system /run/booted-system'    # running vs booted generation
```

`Unknown parameter name` in the error names the parameter the *reader* lacks, so
the record was written by a newer open-iscsi than the one running now —
typically because the node booted an older NixOS generation than the one that
was active before the reboot (`nixos-rebuild switch` without `boot`).

Known parameter changes:

| change | effect |
| --- | --- |
| 2.1.11 → 2.1.12 | `node.session.conn_reopen_log_freq` renamed to `node.session.sess_reopen_log_freq` (open-iscsi#540, Longhorn#13733 — Longhorn's install docs warn about 2.1.12) |
| 2.1.12 → 2.1.13 | `node.session.login_redirect_max` added, so a 2.1.12 `iscsiadm` cannot read a 2.1.13 record |

2026-11-27: the site-wide power event rebooted dubois onto its older generation
(open-iscsi 2.1.12) while its records had been written by 2.1.13 — 294
"config file … invalid" + 147 "failed to start up frontend" in an hour, and a
~4.5 h outage. cuno and katsuragi were unaffected because they had not been
switched.

## Fix

The database is cache; Longhorn re-creates records on attach. Clear it, then let
Longhorn retry (engines retry every ~30 s):

```bash
ssh <node> 'sudo rm -rf /etc/iscsi/nodes/* /etc/iscsi/send_targets/*'
```

Surgical alternative for a single poisoned record (what identified it on
2026-11-27): `sudo grep -rl login_redirect_max /etc/iscsi/nodes | xargs -r sudo rm -rf`.

Do **not** restart `iscsid` to "fix" this — it disturbs live sessions, and it is
not what makes `iscsiadm` re-read the database.

## Prevention

`hosts/revachol-cluster/revachol-common.nix` installs
`iscsi-node-record-guard.service`: a oneshot that runs once per boot, before
`iscsid` (a `/run` marker keeps it from ever firing on a later `iscsid` restart,
when live sessions exist). It runs `iscsiadm -m node -o show` and **only** if
that fails with `Unknown parameter name` / `config file … invalid` does it drop
`/etc/iscsi/nodes` and `/etc/iscsi/send_targets`, log the dropped directories and
the iscsiadm version to the journal, and exit non-zero so the node turns up in
`systemctl --failed`. Any other failure — an `iscsid` that is not up yet, say —
leaves the records alone.

Check it after a node reboot:

```bash
ssh <node> 'systemctl status iscsi-node-record-guard; journalctl -b -u iscsi-node-record-guard'
```

`failed` there is not a boot failure: it means the node came up with a
mismatched open-iscsi and healed itself at the cost of a dropped cache. It is
worth finding out why.

What the guard cannot cover:

- a node that boots an older generation than the one it was running **already
  ran** the mismatched open-iscsi before the guard fired — the guard stops the
  attach path wedging at the next boot, it does not prevent that outage;
- a rollback in place (`nixos-rebuild switch --rollback`) leaves the newer
  version's records in RAM, and `iscsid` is not restarted by a rollback.
  `iscsiadm -m node -o show` (exit 7) is the detector and "Fix" above is the
  remedy;
- the state the fleet is in today — the nodes boot a generation older than
  `flake.lock` declares. That is the discipline half: `nixos-rebuild boot`, never
  a bare `switch`, then a reboot, per
  [cluster-nixos-rebuild.md](cluster-nixos-rebuild.md).

Deliberately not done: mounting a tmpfs over `/etc/iscsi/nodes`. It removes the
failure class without any logic, but it drops the records on every boot instead
of only when they are unreadable, which loses the signal that a node booted a
different open-iscsi.
