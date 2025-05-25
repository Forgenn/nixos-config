let
  system = "x86_64-linux";
  pkgs = import <nixpkgs> { inherit system; };
  agenix = pkgs.agenix;

  # User keys
  ntbUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWhWoSOsaJrYl/srnSkU2riPA/yFCdFC3iZwvZ9Jjv+ node-deploy-key";
  users = [ ntbUserKey ];

  # System keys
  duboisKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQiD6yvuIEdWFrX+mdHomtZZPYZtEvGFqPnm6A1ISeh root@nixos";
  katsuragiKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVn6pB4krq7HO1KbMk3UWRNiUQAtiURLAn8VzmOr9sW root@nixos";
  cunoKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHtJRie1QYS+aJAGFk5k+BN7ZKq+dH8CoharqGOiFp root@nixos";
  systems = [ duboisKey katsuragiKey cunoKey ];

  # Combined keys
  allKeys = users ++ systems;
in
{

  # Secret definitions
  "node_key.age".publicKeys = allKeys;
  "k3s_token.age".publicKeys = allKeys;
  # Add more secrets here, reusing allNodeKeys, allNodeAndUserKeys, or subsets as needed
}
