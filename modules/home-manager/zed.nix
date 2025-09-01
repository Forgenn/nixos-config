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
      font_size = 10;
      theme = {
        light = "One Light";
        dark = "Tokyo Night Storm";
        mode = "system";
      };
      ui_font_size = 10;
      vim_mode = true;
      #wrap_guides = [ 80 ];
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-s" = "workspace::Save";
          "ctrl-p" = "file_finder::Toggle";
          "ctrl-shift-p" = "command_palette::Toggle";
          "ctrl-w" = "pane::CloseActiveItem";
          "ctrl-n" = "workspace::NewFile";
          "ctrl-b" = "project_panel::ToggleFocus";
          "ctrl-`" = "terminal_panel::ToggleFocus";
        };
      }
      {
        context = "Editor";
        bindings = {
          "ctrl-s" = "workspace::Save";
          "ctrl-a" = "editor::SelectAll";
          "ctrl-c" = "editor::Copy";
          "ctrl-v" = "editor::Paste";
          "ctrl-x" = "editor::Cut";
          "ctrl-z" = "editor::Undo";
          "ctrl-shift-z" = "editor::Redo";
          "ctrl-f" = "buffer_search::Deploy";
          "ctrl-d" = "editor::SelectNext";
          "f12" = "editor::GoToDefinition";
          "shift-f12" = "editor::FindAllReferences";
          "f2" = "editor::Rename";
        };
      }
      {
        context = "Dock";
        bindings = {
          "ctrl-w h" = "workspace::ActivatePaneLeft";
          "ctrl-w l" = "workspace::ActivatePaneRight";
          "ctrl-w k" = "workspace::ActivatePaneUp";
          "ctrl-w j" = "workspace::ActivatePaneDown";
        };
      }
    ];
  };
}
