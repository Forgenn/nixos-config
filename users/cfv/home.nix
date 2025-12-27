{
  pkgs,
  user,
  lib,
  ...
}:

{
  home.username = user;
  home.homeDirectory = "/home/${user}";

  # Core user packages
  home.packages = with pkgs; [
    git
    fish
  ];

  programs.bash.enable = false;
  programs.fish.enable = true;

  services.ssh-agent = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      Host katsuragi.home dubois.home cuno.home
        User ntb
        IdentityFile ~/.ssh/id_ed25519
    '';
  };

  # This value determines the Home Manager release that the
  # configuration is compatible with. This helps avoid breakage
  # when receiving updates. It's recommended to set this value.
  # See https://nix-community.github.io/home-manager/reference/options.html#opt-home.stateVersion
  home.stateVersion = "24.11";
}
