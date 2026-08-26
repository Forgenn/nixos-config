let
  system = "x86_64-linux";
  pkgs = import <nixpkgs> { inherit system; };
  agenix = pkgs.agenix;

  # Master key
  masterKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLRHzfP5Bzp+vu/CBsw5US6F7FhAV+Ww5onOag7VaON master-key";

  # User keys
  ntbUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWhWoSOsaJrYl/srnSkU2riPA/yFCdFC3iZwvZ9Jjv+ node-deploy-key";
  users = [ ntbUserKey ];

  # Desktops
  hatsumKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZXSiOpUd9HKAKbY99u33M2zzwrvhKr0wBNXgK2S+b/ root@hatsum";

  desktopKeys = [
    hatsumKey
    # Add master key as well
    masterKey
  ];

  # dolores — not a cluster node (see hosts/revachol-cluster/secrets/secrets.nix) and not
  # a desktop, but this is the closest existing scope rather than a 4th secrets directory.
  # Scoped per-secret below: dolores gets its own recipient list, NOT desktopKeys, so it
  # can't decrypt hatsum's kubeconfig/hermes_env and vice versa.
  doloresKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2CvtEnAPUh38NsFJd7rkesXiSD+dAAbJ0s0DY7DiUo root@nixos";
  ntbUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWhWoSOsaJrYl/srnSkU2riPA/yFCdFC3iZwvZ9Jjv+ node-deploy-key";
  doloresKeys = [ doloresKey ntbUserKey masterKey ];
in
{

  # Secret definitions
  "kubeconfig_revachol.age".publicKeys = desktopKeys;
  "hermes_env.age".publicKeys = desktopKeys;
  "dolores_tailscale_authkey.age".publicKeys = doloresKeys;
}
