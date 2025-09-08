{ pkgs, ... }:
{

    programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      vim-airline
      mini-nvim
      nvim-treesitter
      vim-surround
    ];
    extraConfig = ''
      colorscheme tokyonight-storm
    '';
  };
}
