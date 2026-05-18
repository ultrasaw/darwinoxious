{ config, pkgs, nix-darwin, nixpkgs, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:

{
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # Disable if you don't need x86 apps
    enableRosetta = false;

    # User owning the Homebrew prefix
    user = "doom";

    # Optional: Declarative tap management
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
    };

    # Keep the existing /opt/homebrew/Library/Taps directory; autoUpdate=false avoids mutating pinned taps.
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [
      "homebrew/bundle"
      "homebrew/core"
      "homebrew/cask"
    ];
    brews = import ./brews.nix {};
    casks = import ./casks.nix {};
  };
}
