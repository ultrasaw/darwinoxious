{ config, pkgs, unstablePkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstablePkgs.rustc
    unstablePkgs.cargo
  ];
}
