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
in
{

  # Secret definitions
  "kubeconfig_revachol.age".publicKeys = desktopKeys;
}
