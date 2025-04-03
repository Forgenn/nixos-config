# modules/base.nix
# Example module for settings common to all systems, imported by hosts/common.nix
{ config, pkgs, lib, ... }:

{
  # environment.systemPackages = with pkgs; [
  #   coreutils # Already included, just an example
  # ];

  # Configure console keymap
  console.keyMap = "us";

  # Set default editor system-wide (can be overridden by user config)
  environment.variables.EDITOR = "vim";
}
