# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
 imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.

  #systemd.user.services.plasma-kwin_x11.wantedBy = pkgs.lib.mkForce [];
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable= true;
   
  virtualisation.docker.enable = true;
  
   #services.xserver.displayManager = {
   # sddm.enable = true;
   # defaultSession = "plasma6+i3";
   # session = [
   #   {
   #     manage = "desktop";
   #     name = "plasma6+i3";
   #     start = ''
   #       exec env KDEWM=${pkgs.i3-gaps}/bin/i3 ${pkgs.plasma-workspace}/bin/startplasma-x11
   #     '';
   #   }
   #   {
   #     manage = "window";
   #     name = "i3";
   #     start = ''exec ${pkgs.i3-gaps}/bin/i3'';
   #   }
   # ];
   #};

  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ntb = {
    isNormalUser = true;
    description = "ntb";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  #home-manager.users.ntb = { pkgs, ... }: {
  # home.packages = [ ];
  # programs.bash.enable = true;

   # This value determines the Home Manager release that your configuration is 
   # compatible with. This helps avoid breakage when a new Home Manager release 
   # introduces backwards incompatible changes. 
   #
   # You should not change this value, even if you update Home Manager. If you do 
   # want to update the value, then make sure to first check the Home Manager 
   # release notes. 
  # home.stateVersion = "24.11"; # Please read the comment before changing. 
  #};
  
  ######################
  # EXPERIMENTAL FLAKE!!
  #######################
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; 

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install Bolt Daemon
  services.hardware.bolt.enable = true;
  programs.ssh.startAgent = true;
  programs.ssh.extraConfig = ''
  Host github
    AddKeysToAgent yes
    Hostname github.com
    IdentitiesOnly yes
    IdentityFile  '' + /home/ntb/.ssh/id_ed25519 + ''

  '';
  # Enable Bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # List packages installed in system profile. To search, run:
  # $ nix search wget
       environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        wget
	git
        pkgs.chromium
        vscode
        i3
        code-cursor
	ghostty
        slack
        plasma-browser-integration
	kdePackages.plasma-thunderbolt     
   ];
 
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
