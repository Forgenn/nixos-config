# flake.nix
{
  description = "My NixOS configurations for multiple hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Update tracks. All three follow nixos-26.05; they are SEPARATE inputs so
    # a workstation bump never moves the k3s control plane. One shared nixpkgs
    # meant one `nix flake update` moved all seven machines at once -- and
    # nixpkgs is not pinned for k3s, so that bump carries the cluster's
    # Kubernetes version and the node kernel with it.
    #
    # Renovate groups them by these names with different cadences and soak
    # times (see .github/renovate.json5): workstations weekly/2d, NAS
    # biweekly/7d, cluster monthly/14d. The full "github:" form is required --
    # lockFileMaintenance does not refresh a flake.lock without it
    # (renovatebot/renovate#29721).
    #
    # Design: Forgenn/gitops-cluster docs/plans/2026-09-20-fleet-update-automation.md
    nixpkgs-cluster.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-nas.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # hermes agent
    hermes-agent.url = "github:NousResearch/hermes-agent";
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensures HM uses the same nixpkgs
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # theming
    base16.url = "github:SenchoPens/base16.nix";

    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
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
      hermes-agent,
      agenix,
      base16,
      tt-schemes,
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
          # Which update track this host follows. Defaults to the workstation
          # track; cluster nodes and the NAS pass their own input so their
          # nixpkgs moves on its own schedule.
          pkgsInput ? nixpkgs,
        }:
        pkgsInput.lib.nixosSystem {
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

          # Add modules/inputs
          modules = [
            base16.homeManagerModule
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
        as-pm = mkNixosSystem {
          system = "x86_64-linux";
          device = "as-pm";
          user = "ntb";
          extraModules = [ ./modules/nixos/desktop.nix ];
        };

        ###############
        # t440 laptop
        ###############
        t440 = mkNixosSystem {
          system = "x86_64-linux";
          device = "t440";
          user = "ntb";
          extraModules = [ ./modules/nixos/desktop.nix ];
        };

        ###############
        # hatsum laptop
        ###############
        hatsum = mkNixosSystem {
          system = "x86_64-linux";
          device = "hatsum";
          user = "cfv";
          # Only hatsum actually uses this (the local desktop client, see
          # hosts/hatsum/default.nix) -- was in the shared base module list, applying
          # to every host in the fleet for no reason.
          extraModules = [ hermes-agent.nixosModules.default ];
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
          pkgsInput = inputs.nixpkgs-cluster;
        };

        cuno = mkNixosSystem {
          system = "x86_64-linux";
          device = "revachol-cluster";
          user = "ntb";
          isCluster = true;
          clusterNode = "cuno";
          pkgsInput = inputs.nixpkgs-cluster;
        };

        katsuragi = mkNixosSystem {
          system = "x86_64-linux";
          device = "revachol-cluster";
          user = "ntb";
          isCluster = true;
          clusterNode = "katsuragi";
          pkgsInput = inputs.nixpkgs-cluster;
        };

        ############################
        # dolores — ZFS/NFS storage appliance for the Revachol cluster.
        # Deliberately NOT isCluster: not a k3s node, not part of revachol-common.nix.
        # See hosts/dolores/default.nix for why.
        ############################
        dolores = mkNixosSystem {
          system = "x86_64-linux";
          device = "dolores";
          user = "ntb";
          pkgsInput = inputs.nixpkgs-nas;
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
