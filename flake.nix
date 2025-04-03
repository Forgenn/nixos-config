# flake.nix
{
  description = "My NixOS configurations for multiple hosts";

  inputs = {
    # Nixpkgs (stable or unstable, choose one)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # Or nixos-23.11, etc.

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensures HM uses the same nixpkgs
    };

    # Add other flake inputs here if needed (e.g., overlays, specific apps)
    # hardware.url = "github:NixOS/nixos-hardware"; # Optional: For specific hardware presets
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # Helper function to generate a NixOS configuration
      mkNixosSystem = { system, device, user, extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; }; # Pass inputs and user info down to modules

          modules = [
            # Import host-specific configuration
            ./hosts/${device}

            # Import common host configuration settings
            ./hosts/common.nix

            # Import Home Manager NixOS module
            home-manager.nixosModules.home-manager
            {
              # Configure Home Manager options within the NixOS config
              home-manager.useGlobalPkgs = true; # Use system-wide pkgs for HM
              home-manager.useUserPackages = true; # Allow users to install packages
              # Define users and their Home Manager configurations
              home-manager.users.${user} = import ./home-manager/${user}/home.nix;
              # Add other users managed by HM here if needed
              # home-manager.users.anotherUser = import ./home/anotherUser/home.nix;

              # Pass flake inputs to home-manager modules
              home-manager.extraSpecialArgs = { inherit inputs user; };
            }

            # Add any extra modules specific to this host invocation
          ] ++ extraModules;
        };

    in {
      # Define NixOS configurations for each host
      nixosConfigurations = {
        work-laptop = mkNixosSystem {
          system = "x86_64-linux";
	  device = "work-laptop";          
	  user = "ntb"; # Primary user on laptop
          extraModules = [ ./modules/desktop.nix ]; # Laptop gets desktop modules
        };

        server = mkNixosSystem {
          system = "x86_64-linux";
          device = "server";
          user = "herodotus"; # Primary user on server (can be different)
          # No extra desktop modules for the server
        };
      };

      # Optionally, expose Home Manager configurations standalone
      # homeConfigurations = {
      #   "user1@laptop" = home-manager.lib.homeManagerConfiguration {
      #     pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #     extraSpecialArgs = { inherit inputs; };
      #     modules = [ ./home/user1/home.nix ];
      #   };
      #   "user1@server" = home-manager.lib.homeManagerConfiguration {
      #      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #      extraSpecialArgs = { inherit inputs; };
      #      modules = [ ./home/user1/home.nix ];
      #   };
      # };

      # You can add other outputs like devShells, packages, etc. here
    };
}
