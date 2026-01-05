{ config, pkgs, ... }:

let
  pythonPackages = with pkgs.python3Packages; [
    numpy
  ];

  pythonEnv = pkgs.python3.withPackages (ps: pythonPackages);
in
{
  environment.systemPackages = with pkgs; [
    pythonEnv
    pyright
  ];
}
