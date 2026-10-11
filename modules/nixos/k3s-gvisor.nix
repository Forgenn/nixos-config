{ pkgs, ... }:

# gVisor (runsc) as an extra container runtime for k3s. A pod with `runtimeClassName: gvisor`
# (RuntimeClass in gitops-cluster) runs under gVisor's user-space kernel instead of directly on
# the host's. hrld's developer workbench uses it: it runs untrusted code (dependencies, tests) with
# internet access. Pods without the runtime class keep runc.
{
  # k3s starts containerd, which finds the shim (containerd-shim-runsc-v1) and runsc on its PATH.
  systemd.services.k3s.path = [ pkgs.gvisor ];

  # k3s renders its containerd config from this template; "base" is k3s's own config.
  services.k3s.containerdConfigTemplate = ''
    {{ template "base" . }}

    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
      runtime_type = "io.containerd.runsc.v1"
  '';
}
