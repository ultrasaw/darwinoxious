{ config, pkgs, inputs, theme, system, ... }:

{
  imports = [
    ../home/common.nix
    ../home/looks.nix
    ../home/starship.nix
  ];
}