# flake.nix
{
  description = "My NixOS configurations for multiple hosts";

  inputs = {
    # Nixpkgs (stable or unstable, choose one)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # Or nixos-23.11, etc.
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensures HM uses the same nixpkgs
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add other flake inputs here if needed (e.g., overlays, specific apps)
    # hardware.url = "github:NixOS/nixos-hardware"; # Optional: For specific hardware presets
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixpkgs-unstable,
      agenix,
      ...
    }@inputs:
    let
      # Import all overlays
      overlays = import ./overlays { inherit (inputs) self; };

      # Helper function to generate a NixOS configuration
      mkNixosSystem =
        {
          system,
          device,
          user,
          extraModules ? [ ],
          isCluster ? false,
          clusterNode ? null,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              user
              self
              ;
            #overlays # Directly import patch files
            # Pass resolved paths to overlay files AND patch files
            cursorOverlayModule = ./overlays/cursor-overlay.nix;
            customOpensshOverlayModule = ./overlays/ssh-no-perm-overlay.nix;
            opensshActualPatchFile = ./patches/openssh-nix-dont-checkperm.patch;
          };

          modules = [
            # Enable access to unstable packages
            (
              { config, pkgs, ... }:
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    unstable = import nixpkgs-unstable {
                      inherit (prev) system;
                      config.allowUnfree = true;
                    };
                  })
                ];
                nixpkgs.config.allowUnfree = true;
              }
            )

            # Agenix module for secrets management
            agenix.nixosModules.default

            # Import host-specific configuration
            (
              if isCluster then
                assert clusterNode != null;
                ./hosts/${device}/${clusterNode}/default.nix
              else
                ./hosts/${device}
            )

            # Import Home Manager NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./users/${user}/home.nix;
              home-manager.extraSpecialArgs = { inherit inputs user self; };
            }
          ] ++ extraModules;
        };
    in
    {
      # Define NixOS configurations for each host
      nixosConfigurations = {
        work-laptop = mkNixosSystem {
          system = "x86_64-linux";
          device = "work-laptop";
          user = "ntb";
          extraModules = [ ./modules/nixos/desktop.nix ];
        };

        ############################
        # Revachol cluster nodes
        ############################
        dubois = mkNixosSystem {
          system = "x86_64-linux";
          device = "revachol-cluster";
          user = "ntb";
          isCluster = true;
          clusterNode = "dubois";
        };

        cuno = mkNixosSystem {
          system = "x86_64-linux";
          device = "revachol-cluster";
          user = "ntb";
          isCluster = true;
          clusterNode = "cuno";
        };

        katsuragi = mkNixosSystem {
          system = "x86_64-linux";
          device = "revachol-cluster";
          user = "ntb";
          isCluster = true;
          clusterNode = "katsuragi";
        };
      };

      # homeConfigurations = {
      #   "user1@laptop" = home-manager.lib.homeManagerConfiguration {
      #     pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #     extraSpecialArgs = { inherit inputs; };
      #     modules = [ ./home/user1/home.nix ];
      #   };
    };
}
