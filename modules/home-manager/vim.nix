{ pkgs, ... }:
{

    programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [ tokyonight-nvim vim-airline dracula-vim nvim-treesitter vim-surround];
    extraConfig = ''
      colorscheme tokyonight-storm
    '';
  };
}
