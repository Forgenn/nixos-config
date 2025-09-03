{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      theme = "tokyonight-storm";
      #theme = "Dracula";
      font-family = "BerkeleyMonoTrial Nerd Font";
      font-feature = "calt";
      font-size = "12";
      background-opacity = 0.95;
      background-blur = 40;
      shell-integration = "fish";
      cursor-click-to-move = true;
      command = "fish";
      keybind = [
        "ctrl+backspace=text:\\x15"
      ];
    };
  };
}
