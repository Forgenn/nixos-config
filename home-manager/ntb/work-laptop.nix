{ config, pkgs, lib, ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host github.com
         AddKeysToAgent yes
         Hostname github.com
         IdentitiesOnly yes
         IdentityFile  ~/.ssh/id_ed25519_ais

      Host p.github.com
         AddKeysToAgent no
         Hostname github.com
         IdentitiesOnly yes
         IdentityFile  ~/.ssh/id_ed25519
      
      Host gitlab.com
              AddKeysToAgent yes
              Hostname gitlab.com
              IdentitiesOnly yes
              IdentityFile  ~/.ssh/id_ed25519
    '';
  };
} 