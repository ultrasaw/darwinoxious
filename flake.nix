# flake.nix
{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager }:
    let
      lib = nixpkgs.lib;
      targetSystem = "aarch64-darwin";
      unstablePkgs = import nixpkgs-unstable {
        system = targetSystem;
        config.allowUnfree = true;
      };

      configuration = { pkgs, ... }: {
        system.primaryUser = "doom";

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [
          pkgs.vim
        ];

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Enable alternative shell support in nix-darwin.
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = targetSystem;
        nixpkgs.config.allowUnfree = true;
      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#book-of-doom
      darwinConfigurations."book-of-doom" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs homebrew-bundle homebrew-core homebrew-cask unstablePkgs;
        };
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          ./modules/homebrew.nix
          ./modules/user.nix
          ./modules/terminals.nix
          ./modules/python.nix
          ./modules/go.nix
          ./modules/rust.nix
        ];
      };
    };
}
