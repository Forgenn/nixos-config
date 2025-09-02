{ pkgs, ... }:
{

    programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-airline dracula-vim];
    extraConfig = ''
      colorscheme dracula
    '';
    settings = { 
      ignorecase = true;
      copyindent= true; 
    };
  };
}
