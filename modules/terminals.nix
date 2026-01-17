# modules/terminals.nix
# Terminal emulators (Alacritty, Kitty) - installed as system packages for proper /Applications linking
{ pkgs, config, lib, ... }:

{
  # GUI apps in environment.systemPackages get linked to /Applications/Nix Apps/
  environment.systemPackages = [
    pkgs.alacritty
    pkgs.kitty
  ];

  # Use mkalias to create real macOS aliases instead of symlinks
  # This allows Spotlight to index the apps properly
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications/Nix Apps..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' ';' |
      while read -r src; do
        app_name=$(basename "$src")
        echo "creating alias for $app_name" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';
}
