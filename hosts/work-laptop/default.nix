# hosts/laptop/default.nix
{ config, pkgs, lib, inputs, user, cursorOverlayFile, customOpensshOverlayFile, opensshDontCheckPermPatch, ... }: # Note the 'user' arg passed from flake.nix

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  # Hostname
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # Laptop specific settings
 
 
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Install Bolt Daemon
  services.hardware.bolt.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  services.upower.enable = true;
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;

  # Define the primary user account on this system
  users.users.${user} = {
    isNormalUser = true;
    description = "ntb";
    extraGroups = [ "docker" "networkmanager" "wheel" "video" "audio" ]; # 'wheel' for sudo access
    initialHashedPassword = "*"; # Set a password manually or use home-manager/impermanence
    openssh.authorizedKeys.keys = [
      # Add your SSH public key(s) here
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo"
    ];
  };

  security.sudo.wheelNeedsPassword = true; # Or true if you prefer

  # Firewall settings (example)
  networking.firewall.enable = false;
  #networking.firewall.allowedTCPPorts = [ 22, 47 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
  ];
  
    nixpkgs.overlays = [
    (
      (import customOpensshOverlayFile {
        inherit pkgs lib; # pkgs here is the set *before* this specific overlay is fully applied by Nix
        patchFile = opensshDontCheckPermPatch;
      })
    )
    # Your inline overlay for Cursor
    (
      # Call the outer function of the overlay, passing pkgs and lib
      (import cursorOverlayFile { inherit pkgs lib; }) # Adjust path if needed
      # Call the inner function with your specific Cursor details
      {
        newCursorVersion = "0.50.4";
        newCursorUrl = "https://downloads.cursor.com/production/8ea935e79a50a02da912a034bbeda84a6d3d355d/linux/x64/Cursor-0.50.4-x86_64.AppImage";
        # Replace with the actual SHA256 hash after the first failed build
        newCursorSha256 = "sha256-ik+2TqmRhnzXM+qoCQ+KLQkW/cqZSqcZS2P2yuUPGI8=";
        # cursorPname = "code-cursor"; # Optional, defaults to "code-cursor" in the overlay file
      }
    ) #You can add other overlays here if needed
  ];
  # Laptop specific packages (less common, prefer home-manager)
   environment.systemPackages = with pkgs; [ 
        pkgs.chromium
        vscode
        ghostty
        starship
        slack
        buf
        #overlay
        code-cursor
        pkgs.unstable.openbao
        # Home integrations
        pkgs.unstable.deskflow
        sunshine
        # Programming things
        uv
        python311
        python312
        go
        nodejs_23
        postman
        jq
        bambu-studio
        # GCP things
        opentofu
        kubernetes-helm
        google-cloud-sdk
        k9s
        kubectl
        (pkgs.google-cloud-sdk.withExtraComponents [pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin])
        #Kde things
        kdePackages.powerdevil
        kdePackages.kwallet
        kdePackages.kwallet-pam
        kdePackages.plasma-browser-integration
        kdePackages.plasma-thunderbolt
   ];
  
  ##########################
  #  Program configuration
  ##########################
  # Make vscode/cursor ssh work
  programs.nix-ld.enable = true;

  programs.ssh = {
   enable = true;
   # Impure Identity file config? Throws purity error if not a literal
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

  services.openssh.settings.X11Forwarding = true;
  
  home-manager.users.${user} = {
   programs.git = {
      # Use lib.mkOverride to ensure these values take precedence over
      # any potential definitions in home.nix or common.nix.
      # Priority 10 is a common choice for overrides.
      userName = lib.mkOverride 10 "ntb";
      userEmail = lib.mkOverride 10 "pol.monedero@aistechspace.com";
    };

    # --- Configure i3 Startup for Work Laptop Display Layout ---
    # Define host-specific i3 startup commands here.
    # These will be MERGED with the startup items defined in home-manager/modules/i3.nix
    # thanks to the Nix/Home Manager module system's list merging.
    xsession.windowManager.i3.config.startup = lib.mkAfter [
      {
        # Use 'exec --no-startup-id' or just 'command' if HM handles exec wrapper
        # Using a direct command string is typical here.
        command = "exec ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1200 --pos 3000x824 --rotate normal --scale 0.5x0.5 --filter nearest --auto --output DP-10 --mode 1920x1080 --pos 0x0 --rotate left   --scale 1x1 --auto --output DP-9 --mode 1920x1080 --pos 1080x420 --rotate normal --scale 1x1 --auto";
        # These settings ensure it runs once at startup and not on i3 reload
        always = false;
        notification = false;
      }
    ];
    xsession.windowManager.i3.config.workspaceOutputAssign = lib.mkOverride 10 [
            { output = "eDP-1"; workspace = "1"; }
            { output = "eDP-1"; workspace = "2"; }
            { output = "eDP-1"; workspace = "3"; }
            { output = "DP-8"; workspace = "4"; }
            { output = "DP-8"; workspace = "5"; }
            { output = "DP-8"; workspace = "6"; }
            { output = "DP-7"; workspace = "7"; }
            { output = "DP-7"; workspace = "8"; }
            { output = "DP-7"; workspace = "9"; }
     ];
 };
}
