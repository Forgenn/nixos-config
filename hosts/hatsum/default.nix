# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, user, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common.nix
      ../../modules/nixos/chromium.nix
    ];

  # --- Shared Storage Mounts ---
  # Note: These options are for filesystems like NTFS/exFAT that don't
  # support native Linux permissions.
  fileSystems."/mnt/Hydrogen" = {
    device = "/dev/disk/by-uuid/8042273542272F7A";
    fsType = "ntfs";
    options = [
      "nofail"
      "defaults"
      "uid=0" # Owner is root
      "gid=${builtins.toString config.users.groups.storage.gid}" # Group is our new 'storage' group
      "umask=007" # Permissions: 770 for dirs, 660 for files
    ];
  };

  fileSystems."/mnt/Helium" = {
      device = "/dev/disk/by-uuid/2ea90fcc-3fbd-4c64-b220-3344eac0ce77";
      fsType = "ext4";
      options = [ "nofail" "defaults" ];
      # "defaults" implies "exec", "rw", etc.
  };


  # Bootloader.
  boot.loader.grub.enable = lib.mkForce true;
  boot.loader.grub.device = lib.mkForce "/dev/sda";
  boot.loader.grub.useOSProber = lib.mkForce true;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.plymouth.enable = true;
  boot.plymouth.theme = "breeze";

  networking.hostName = "hatsum"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Hibernation
  boot.resumeDevice = "/dev/disk/by-uuid/0f8378bc-1077-4d6f-a174-84c759d96c9d";
  boot.kernelParams = [ "resume=UUID=0f8378bc-1077-4d6f-a174-84c759d96c9d" ];


  # GPU config
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.initrd.enable = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

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

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "es_ES.UTF-8/UTF-8" "en_GB.UTF-8/UTF-8" ];

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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


  # Define a group for shared storage access
  users.groups.storage = { gid = 1002; };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Temporary, remove once in
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.X11Forwarding = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cfv = {
    isNormalUser = true;
    description = "cfv";
    extraGroups = [ "networkmanager" "wheel" "storage" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo" # ntb user
    ];

    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  users.users.mire = {
    isNormalUser = true;
    description = "mire";
    extraGroups = [ "networkmanager" "wheel" "storage" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlMp3gOmuiGEjtG7d/c7CIqQpId49EZoX5Nu1J6Pfuo" # ntb user
    ];

    packages = with pkgs; [
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Enable agenix for secret decryption
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets.kubeconfig_revachol = {
      file = ../secrets/kubeconfig_revachol.age;
      mode = "600";
      owner = "cfv";
      group = "users";
      path = "/home/cfv/.kube/config";
    };

  programs.nix-ld.enable = true;

  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    heroic
    umu-launcher
    chromium
    gemini-cli
    orca-slicer
    discord
    inputs.agenix.packages.${pkgs.system}.default
  ];

# --- Home Manager ---
  home-manager.users.${user} =
    {
      pkgs,
      lib,
      self,
      osConfig,
      ...
    }:
    {
      imports = [
        (self + "/modules/home-manager/base.nix")
        (self + "/modules/home-manager/fish+starship.nix")
        (self + "/modules/home-manager/ghostty.nix")
        (self + "/modules/home-manager/zed.nix")
        (self + "/modules/home-manager/vim.nix")
        (self + "/modules/home-manager/btop.nix")
        (self + "/modules/home-manager/k9s.nix")
      ];

      # secret symlinks
      # home.file.".kube/config".source = config.lib.file.mkOutOfStoreSymlink osConfig.age.secrets.kubeconfig_revachol.path;


      home.packages = with pkgs; [
        starship
        nixfmt-rfc-style
        kubernetes-helm
        kubectl
        (pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
        bitwarden-desktop
      ];

      # For orcaslicer bug
      home.sessionVariables = {
        _EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
        WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      };

      programs.zed-editor.userSettings.ui_font_size = lib.mkForce 18;

      programs.git = {
        enable = true;
        userName = lib.mkDefault "ntb";
        userEmail = lib.mkDefault "ipolmonxammar@gmail.com";
      };

      programs.ssh.extraConfig = ''
        Host github.com
           Hostname github.com
           AddKeysToAgent yes
           IdentityFile  ~/.ssh/id_ed25519
      '';
    };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
