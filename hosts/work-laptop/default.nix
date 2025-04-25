# hosts/laptop/default.nix
{ config, pkgs, lib, inputs, user, ... }: # Note the 'user' arg passed from flake.nix

{
  imports = [
    # Include the hardware configuration specific to this laptop
    ./hardware-configuration.nix
    # You could import other laptop-specific modules here
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
    ];
  };

  security.sudo.wheelNeedsPassword = true; # Or true if you prefer

  # Firewall settings (example)
  # networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Laptop specific packages (less common, prefer home-manager)
   environment.systemPackages = with pkgs; [ 
        pkgs.chromium
        vscode
        ghostty
        slack
	buf
	pkgs.unstable.deskflow
	# Programming things
	uv
	python311
	python312
	postman
	# GCP things
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
  home-manager.users.${user} = {
   programs.ssh.enable = true;
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
        command = "${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 2560x1600 --pos 3000x824 --rotate normal --scale 1x1 --auto --output DP-10 --mode 1920x1080 --pos 0x0 --rotate left   --scale 1x1 --auto --output DP-9 --mode 1920x1080 --pos 1080x420 --rotate normal --scale 1x1 --auto";
        # These settings ensure it runs once at startup and not on i3 reload
        always = false;
        notification = false;
      }
    ];
    xsession.windowManager.i3.config.workspaceOutputAssign = lib.mkOverride 10 [
            { output = "eDP-1"; workspace = "1"; }
            { output = "eDP-1"; workspace = "2"; }
            { output = "eDP-1"; workspace = "3"; }
            { output = "DP-7"; workspace = "4"; }
            { output = "DP-7"; workspace = "5"; }
            { output = "DP-7"; workspace = "6"; }
            { output = "DP-8"; workspace = "7"; }
            { output = "DP-8"; workspace = "8"; }
            { output = "DP-8"; workspace = "9"; }
     ];

    # Add other work-laptop-specific HM settings for 'ntb' here if needed
    # e.g., enabling specific work applications or services

  
  #home.homeDirectory = /home/${user};

 };
}
