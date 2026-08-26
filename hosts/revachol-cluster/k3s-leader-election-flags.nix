# Shared by dubois/master-k3s-config.nix and node-config.nix (cuno/katsuragi) -- every
# k3s server node runs kube-controller-manager/kube-scheduler/kube-cloud-controller-manager,
# only one active per component at a time via lease, so all server nodes need the same
# widened timeouts regardless of which one is currently leading.
#
# Root cause: dubois's NVMe is a bottom-tier DRAM-less drive whose fsync latency
# collapses under write pressure (idle ~1.75ms, observed up to a 79.5s continuously-
# blocked WAL episode). The default 15s/10s/2s leader-election timing meant any stall
# past ~10s made these components call os.Exit(1), taking etcd and the apiserver down
# with them. Widened to clear the worst observed stall with margin. Does not fix the
# underlying slow disk -- only stops a disk hiccup from cascading into a full outage.
# The HA conversion (node-config.nix: cuno/katsuragi now role=server) is the real
# mitigation -- a 3-member etcd quorum only needs 2-of-3 acks, so one slow member no
# longer single-handedly blocks the cluster.
[
  "--kube-controller-manager-arg=leader-elect-lease-duration=120s"
  "--kube-controller-manager-arg=leader-elect-renew-deadline=90s"
  "--kube-controller-manager-arg=leader-elect-retry-period=10s"
  "--kube-scheduler-arg=leader-elect-lease-duration=120s"
  "--kube-scheduler-arg=leader-elect-renew-deadline=90s"
  "--kube-scheduler-arg=leader-elect-retry-period=10s"
  "--kube-cloud-controller-manager-arg=leader-elect-lease-duration=120s"
  "--kube-cloud-controller-manager-arg=leader-elect-renew-deadline=90s"
  "--kube-cloud-controller-manager-arg=leader-elect-retry-period=10s"
]
