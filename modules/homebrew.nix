{ config, pkgs, nix-darwin, nixpkgs, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:

{
  # Ensure Homebrew directories exist before nix-homebrew runs
  # Clean up broken symlinks from garbage collection
  system.activationScripts.preHomebrewSetup.text = ''
    for prefix in /opt/homebrew /usr/local/Homebrew; do
      if [ -d "$prefix" ]; then
        mkdir -p "$prefix/Library/Taps" 2>/dev/null || true
        # Remove broken Taps symlink if it exists
        [ -L "$prefix/Library/Taps" ] && [ ! -e "$prefix/Library/Taps" ] && rm "$prefix/Library/Taps"
      fi
    done
  '';

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

    # Optional: Enable fully-declarative tap management
    #
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = true;
  };
}
