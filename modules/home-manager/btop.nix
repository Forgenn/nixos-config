{ ... }:
{
  ########################################################################
  # --- btop config ---
  ########################################################################
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "nord";
      theme_background = false;
      vim_keys = true;
      rounded_corners = true;
    };
  };
}
