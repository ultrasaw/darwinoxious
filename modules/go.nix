{ config, pkgs, unstablePkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstablePkgs.go
    unstablePkgs.gopls
    unstablePkgs.gotools
    unstablePkgs.golangci-lint
    unstablePkgs.golangci-lint-langserver
  ];
}
