{ config, pkgs, lib, inputs, home-manager, unstablePkgs, ... }:

let
  user = "doom";
in
{
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    brews = pkgs.callPackage ./brews.nix {};
    taps = [
      "fluxcd/tap"
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs unstablePkgs;
    };
    users = {
      "${user}" = import ./home.nix;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
