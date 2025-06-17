{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      theme = "Dracula";
      font-family = "Fira Code";
      background-opacity = 0.95;
      background-blur = 40;
      shell-integration = "fish";
      command = "fish";
      keybind = [
        "ctrl+backspace=text:\\x15"
      ];
    };
  };
}
