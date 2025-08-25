{ pkgs, ... }:
{
  ########################################################################
  # --- Cursor config ---
  ########################################################################
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    #mutableExtensionsDir = true;
    profiles.default = {
      userSettings = {
        "editor.cursorBlinking" = "smooth";
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "window.commandCenter" = true;
        #"workbench.colorTheme" = "SynthWave '84";
        #"workbench.colorTheme" = "Monokai Pro (Filter Spectrum)";
        #"workbench.colorTheme" = "Monokai Classic";
        "workbench.colorTheme" = "Tokyo Night Storm";
        "workbench.tree.indent" = 24;
        "git.autofetch" = true;
        "vs-kubernetes" = {
          "vs-kubernetes.crd-code-completion" = "enabled";
        };
        "terminal.external.linuxExec" = "ghostty";
        "terminal.integrated.defaultProfile.linux" = "fish";
        "editor.fontFamily" = "'Fira Code'";
        "editor.fontLigatures" = true;
        "docker.extension.experimental.composeCompletions" = true;
        "workbench.activityBar.orientation" = "vertical";
        "vim.handleKeys" = {
          "<C-c>" = false;
          "<C-x>" = false;
          "<C-v>" = false;
          "<C-a>" = false;
          "<C-z>" = false;
          "<C-f>" = false;
          "<C-s>" = true;
          "<C-p>" = false;
        };
        "remote.SSH.remotePlatform" = {
          "pol@compilaistron.wks.aistech" = "linux";
        };
      };

      extensions = with pkgs.vscode-extensions; [
        golang.go
        matangover.mypy
        redhat.vscode-yaml
        charliermarsh.ruff
        ms-python.python
        jnoortheen.nix-ide
        vscodevim.vim
        enkia.tokyo-night
        google.gemini-cli-vscode-ide-companion
        # Unavaible nixos, install
        #monokai.theme-monokai-pro-vscode
      ];
    };
  };
}
