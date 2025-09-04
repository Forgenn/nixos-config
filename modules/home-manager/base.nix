{ inputs,
  ... }:
{
  #########################
  # --- NH config ---
  #########################
  imports = [
    ./nh.nix
    ./btop.nix
    ./vim.nix
    inputs.base16.homeManagerModule
  ];
  scheme = "${inputs.tt-schemes}/base16/tokyo-night-terminal-storm.yaml";
}
