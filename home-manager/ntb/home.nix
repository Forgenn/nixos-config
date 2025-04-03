# home/user1/home.nix
# Home Manager configuration specific to 'user1'
{ config, pkgs, lib, inputs, user, ... }: # Note 'user' is available if passed via specialArgs

{
  imports = [
    # Import common home-manager settings
    ./../common.nix
    # You could import role-specific HM configs here (e.g., ./../desktop-hm.nix)
  ];
  home.homeDirectory = "/home/${user}";
  # User-specific packages
  home.packages = with pkgs; [
    # Add packages only 'user1' needs
    fish # Example: using zsh instead of bash
    # starship # Example: prompt for zsh
  ];

  # Override or extend common settings
  programs.bash.enable = false; # Disable bash if using zsh
  programs.fish = {
    enable = true;
  };

  # User-specific dotfiles
  home.file.".config/user1-specific.txt".text = ''
    Configuration specific to user1. My user variable is: ${user}
  '';
  
  ##########################
  #  Program configuration
  ##########################
  # Work mail should be on work laptop config
  services.ssh-agent = {
    enable = true;
  };

  programs.ssh = {
   enable = true;
   # Impure Identity file config? Throws purity error if not a literal
   extraConfig = ''
        Host github
           AddKeysToAgent yes
           Hostname github.com
           IdentitiesOnly yes
           IdentityFile  ~/.ssh/id_ed25519

        Host gitlab
          AddKeysToAgent yes
          Hostname gitlab.com
          IdentitiesOnly yes
          IdentityFile  ~/.ssh/id_ed25519

    '';
   };

  # Example: Link dotfiles from the config repository
  # home.file.".config/nvim" = {
  #   source = ./config/nvim; # Assumes ./config/nvim exists relative to this file
  #   recursive = true;
  # };

  # Desktop specific settings for user1 (conditional on host type if needed)
  # Maybe use lib.mkIf config.networking.hostName == "laptop" { ... }
  # programs.vscode = {
  #   enable = true;
  #   # extensions = with pkgs.vscode-extensions; [ ... ];
  # };
}
