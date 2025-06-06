let
  system = "x86_64-linux";
  pkgs = import <nixpkgs> { inherit system; };
  agenix = pkgs.agenix;

  # Master key
  masterKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLRHzfP5Bzp+vu/CBsw5US6F7FhAV+Ww5onOag7VaON master-key";

  # User keys
  ntbUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWhWoSOsaJrYl/srnSkU2riPA/yFCdFC3iZwvZ9Jjv+ node-deploy-key";
  users = [ ntbUserKey ];

  # System keys
  duboisKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQiD6yvuIEdWFrX+mdHomtZZPYZtEvGFqPnm6A1ISeh root@nixos";
  katsuragiKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVn6pB4krq7HO1KbMk3UWRNiUQAtiURLAn8VzmOr9sW root@nixos";
  cunoKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHtJRie1QYS+aJAGFk5k+BN7ZKq+dH8CoharqGOiFp root@nixos";
  systems = [
    duboisKey
    katsuragiKey
    cunoKey
  ];

  # Combined keys
  allKeys = users ++ systems ++ [ masterKey ];
in
{

  # Secret definitions
  "github_node_key.age".publicKeys = allKeys;
  "k3s_token.age".publicKeys = allKeys;
  "nas_node_key.age".publicKeys = allKeys;
  "gitops_deploy_key.age".publicKeys = allKeys;
  # Add more secrets here, reusing allNodeKeys, allNodeAndUserKeys, or subsets as needed
}
