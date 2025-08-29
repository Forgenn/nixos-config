{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;
    extensions = [
      "dockerfile"
      "dracula"
      "nix"
      "go"
      "python"
      "yaml"
      "json"
    ];

    userSettings = {
      languages = {
        Nix = {
          language_servers = [
            "nil"
            "!nixd"
          ];
        };
      };
      font_family = "JetBrains Mono";
      font_size = 14;
      theme = {
        light = "One Light";
        dark = "Tokyo Night Storm";
        mode = "system";
      };
      ui_font_size = 14;
      vim_mode = true;
      #wrap_guides = [ 80 ];
    };
  };
}
