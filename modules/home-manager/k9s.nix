{ config, lib, ... }:
{
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        skin = "tokyonight_night";
        cluster = "default";
        ui = {
          enableMouse = true;
          headless = false;
          logoless = false;
          crumbsless = false;
        };
      };
    };

    #https://github.com/axkirillov/k9s-tokyonight
    skins.tokyonight_night = with config.scheme.withHashtag; {
      k9s = {
        body = { fgColor = base06-hex; bgColor = "default"; logoColor = base0D-hex; };
        prompt = { fgColor = base06-hex; bgColor = base00-hex; suggestColor = base09-hex; };
        info = { fgColor = base0E-hex; sectionColor = base06-hex; };
        dialog = { fgColor = base06-hex; bgColor = "default"; buttonFgColor = base06-hex; buttonBgColor = base0E-hex; buttonFocusFgColor = base00-hex; buttonFocusBgColor = base06-hex; labelFgColor = base03-hex; fieldFgColor = base06-hex; };
        frame = {
          border = { fgColor = base02-hex; focusColor = base06-hex; };
          menu = { fgColor = base06-hex; keyColor = base0E-hex; numKeyColor = base0E-hex; };
          crumbs = { fgColor = base05-hex; bgColor = base0C-hex; activeColor = base0A-hex; };
          status = { newColor = base0E-hex; modifyColor = base0D-hex; addColor = base0B-hex; errorColor = base08-hex; highlightcolor = base09-hex; killColor = base03-hex; completedColor = base03-hex; };
          title = { fgColor = base06-hex; bgColor = "default"; highlightColor = base0D-hex; counterColor = base0E-hex; filterColor = base0E-hex; };
        };
        views = {
          charts = { bgColor = "default"; defaultDialColors = [ base0D-hex base08-hex ]; defaultChartColors = [ base0D-hex base08-hex ]; };
          table = { fgColor = base06-hex; bgColor = "default"; cursorFgColor = base05-hex; cursorBgColor = base00-hex; markColor = "darkgoldenrod"; header = { fgColor = base06-hex; bgColor = "default"; sorterColor = base0C-hex; }; };
          xray = { fgColor = base06-hex; bgColor = "default"; cursorColor = base01-hex; graphicColor = base0D-hex; showIcons = false; };
          yaml = { keyColor = base0E-hex; colonColor = base0D-hex; valueColor = base06-hex; };
          logs = { fgColor = base06-hex; bgColor = "default"; indicator = { fgColor = base06-hex; bgColor = base02-hex; }; };
          help = { fgColor = base06-hex; bgColor = "default"; indicator = { fgColor = base08-hex; bgColor = base02-hex; }; };
        };
      };
    };
  };
}
